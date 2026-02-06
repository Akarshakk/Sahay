import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Service for handling audio recording and Whisper-based transcription
/// Uses the backend API to transcribe audio using OpenAI Whisper
class WhisperTranscriptionService {
  final String baseUrl;
  
  WhisperTranscriptionService({required this.baseUrl});
  
  /// Transcribe audio file using Whisper via backend
  /// 
  /// [audioPath] - Path to the audio file to transcribe
  /// Returns transcription result with text, language, and segments
  Future<TranscriptionResult> transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw TranscriptionException('Audio file not found: $audioPath');
      }
      
      final uri = Uri.parse('$baseUrl/transcription/speech-to-text');
      final request = http.MultipartRequest('POST', uri);
      
      // Add the audio file
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
      ));
      
      debugPrint('Sending audio for transcription: $audioPath');
      
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw TranscriptionException('Transcription request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return TranscriptionResult.fromJson(data['data']);
        } else {
          throw TranscriptionException(data['message'] ?? 'Transcription failed');
        }
      } else {
        final error = jsonDecode(response.body);
        throw TranscriptionException(error['message'] ?? 'Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw TranscriptionException('Network error. Please check your connection.');
    } on FormatException {
      throw TranscriptionException('Invalid response from server');
    } catch (e) {
      if (e is TranscriptionException) rethrow;
      throw TranscriptionException('Transcription failed: $e');
    }
  }
  
  /// Transcribe audio bytes directly (useful for recorded audio)
  Future<TranscriptionResult> transcribeBytes(Uint8List audioBytes, {String extension = 'wav'}) async {
    try {
      // Save bytes to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await tempFile.writeAsBytes(audioBytes);
      
      try {
        // Transcribe the file
        final result = await transcribeAudio(tempFile.path);
        return result;
      } finally {
        // Cleanup temp file
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      if (e is TranscriptionException) rethrow;
      throw TranscriptionException('Failed to process audio: $e');
    }
  }
}

/// Result of a transcription
class TranscriptionResult {
  final String text;
  final String language;
  final List<TranscriptionSegment> segments;
  
  TranscriptionResult({
    required this.text,
    required this.language,
    this.segments = const [],
  });
  
  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] ?? '',
      language: json['language'] ?? 'unknown',
      segments: (json['segments'] as List<dynamic>?)
          ?.map((s) => TranscriptionSegment.fromJson(s))
          .toList() ?? [],
    );
  }
  
  bool get isEmpty => text.isEmpty;
  bool get isNotEmpty => text.isNotEmpty;
}

/// A segment of transcribed audio with timing
class TranscriptionSegment {
  final double start;
  final double end;
  final String text;
  
  TranscriptionSegment({
    required this.start,
    required this.end,
    required this.text,
  });
  
  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      start: (json['start'] as num?)?.toDouble() ?? 0,
      end: (json['end'] as num?)?.toDouble() ?? 0,
      text: json['text'] ?? '',
    );
  }
  
  Duration get startDuration => Duration(milliseconds: (start * 1000).round());
  Duration get endDuration => Duration(milliseconds: (end * 1000).round());
}

/// Exception for transcription errors
class TranscriptionException implements Exception {
  final String message;
  TranscriptionException(this.message);
  
  @override
  String toString() => message;
}
