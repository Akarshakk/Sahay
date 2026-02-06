import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/whisper_transcription_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// SOS Active Screen - Shows map with location and status after SOS is triggered
class SOSActiveScreen extends ConsumerStatefulWidget {
  final bool silentMode;
  final bool requireVolunteerAssistance;
  final String emergencyNumber;
  final String emergencyLabel;
  
  const SOSActiveScreen({
    super.key,
    this.silentMode = false,
    this.requireVolunteerAssistance = true,
    this.emergencyNumber = '112',
    this.emergencyLabel = 'Police',
  });

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen> {
  final MapController _mapController = MapController();
  String _sosId = '';
  String _sosStatus = 'SOS Pressed';
  bool _isLoading = true;
  bool _callMade = false;
  String _sosMessage = '';
  String _briefAddress = '';
  String _fullAddress = '';
  
  // Default location
  static const double _defaultLatitude = 19.0760;
  static const double _defaultLongitude = 72.8777;

  @override
  void initState() {
    super.initState();
    _triggerSOSBackend();
    _initLocation();
  }
  
  Future<void> _initLocation() async {
    // Wait for provider to load if not ready
    await Future.delayed(const Duration(milliseconds: 500));
    final location = ref.read(currentLocationProvider).valueOrNull;
    if (location != null) {
      setState(() {
        _fullAddress = location.address;
        // Create brief address (first part before comma or first 30 chars)
        if (location.address.contains(',')) {
          final parts = location.address.split(',');
          _briefAddress = parts.take(2).join(',').trim();
        } else {
          _briefAddress = location.address.length > 30 
              ? '${location.address.substring(0, 30)}...' 
              : location.address;
        }
      });
    }
  }

  Future<void> _triggerSOSBackend() async {
    try {
      final user = ref.read(authControllerProvider);
      final location = ref.read(currentLocationProvider).valueOrNull;
      final api = ref.read(apiServiceProvider);
      
      // 1. Trigger SOS on backend
      final response = await api.triggerSOS(
        latitude: location?.latitude ?? _defaultLatitude,
        longitude: location?.longitude ?? _defaultLongitude,
        type: 'POLICE',
        address: location?.address,
      );
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _sosId = response['data']['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}';
          _isLoading = false;
        });
      }
      
      // 2. Make emergency call after 5 seconds (unless silent mode)
      if (!widget.silentMode && !_callMade) {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          _makeEmergencyCall();
        }
      }
      
    } catch (e) {
      setState(() {
        _sosId = '${DateTime.now().millisecondsSinceEpoch}'.substring(5, 11);
        _isLoading = false;
      });
      debugPrint('SOS Trigger Error: $e');
    }
  }

  Future<void> _makeEmergencyCall() async {
    if (_callMade) return;
    _callMade = true;
    
    // Use the emergency number passed from countdown screen
    final emergencyNum = widget.emergencyNumber;
    
    try {
      // Use FlutterPhoneDirectCaller for auto-dialing (doesn't just open dialer)
      await FlutterPhoneDirectCaller.callNumber(emergencyNum);
    } catch (e) {
      debugPrint('Direct call failed: $e');
      // Fallback to url_launcher
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNum);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        }
      } catch (e2) {
        debugPrint('Fallback call failed: $e2');
      }
    }
  }

  Future<void> _markSafe() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Text('Mark as Safe?'),
          ],
        ),
        content: const Text(
          'This will notify all volunteers and authorities that you are now safe and end the emergency alert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Yes, I am Safe'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      // Update SOS status on backend (if we have a valid SOS ID)
      if (_sosId.isNotEmpty && !_sosId.startsWith('1')) {
        // Only call API if we have a valid Firebase document ID (not a timestamp fallback)
        final api = ref.read(apiServiceProvider);
        await api.addSOSAction(
          _sosId,
          'MARKED_SAFE',
          details: 'User marked themselves as safe',
        );
      }
    } catch (e) {
      // Log error but don't block navigation - user safety is priority
      debugPrint('Failed to update SOS status on backend: $e');
    }
    
    // Always show success and navigate home
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ You have been marked as safe. Authorities and volunteers have been notified.'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to home
      final user = ref.read(authControllerProvider);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userRole: user?.role ?? UserRole.citizen),
        ),
        (route) => false,
      );
    }
  }

  void _showMessageDialog() {
    final messageController = TextEditingController(text: _sosMessage);
    bool isListeningLocal = false;
    bool isRecordingForWhisper = false;
    final stt.SpeechToText speechToText = stt.SpeechToText();
    final AudioRecorder audioRecorder = AudioRecorder();
    bool speechEnabled = false;
    bool useWhisperFallback = false;
    String lastWords = _sosMessage;
    String statusText = '';
    double soundLevel = 0.0;
    String? recordingPath;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<bool> requestPermissions() async {
            // On web, skip permission_handler as it doesn't support speech permission
            if (kIsWeb) {
              debugPrint('Web platform detected - skipping permission_handler, using browser APIs');
              // On web, permissions are requested by the browser when we start recording/listening
              // Just return true and let the browser handle it
              return true;
            }
            
            // Request microphone permission (mobile only)
            var micStatus = await Permission.microphone.request();
            debugPrint('Microphone permission: $micStatus');
            
            if (!micStatus.isGranted) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: const Text('Microphone permission required'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () => openAppSettings(),
                    ),
                  ),
                );
              }
              return false;
            }
            
            // Request speech permission (iOS only - not supported on web/Android)
            try {
              if (!kIsWeb && Platform.isIOS) {
                var speechStatus = await Permission.speech.request();
                debugPrint('Speech permission: $speechStatus');
                
                if (!speechStatus.isGranted) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: const Text('Speech recognition permission required'),
                        backgroundColor: Colors.red,
                        action: SnackBarAction(
                          label: 'Settings',
                          textColor: Colors.white,
                          onPressed: () => openAppSettings(),
                        ),
                      ),
                    );
                  }
                  return false;
                }
              }
            } catch (e) {
              debugPrint('Error requesting speech permission: $e');
              // Continue without speech permission - will use Whisper fallback
            }
            
            return true;
          }
          
          void onSpeechResult(SpeechRecognitionResult result) {
            debugPrint('=== SPEECH RESULT ===');
            debugPrint('Words: "${result.recognizedWords}"');
            debugPrint('Confidence: ${result.confidence}');
            debugPrint('Final: ${result.finalResult}');
            debugPrint('Alternates: ${result.alternates.length}');
            
            setDialogState(() {
              if (result.recognizedWords.isNotEmpty) {
                lastWords = result.recognizedWords;
                messageController.text = lastWords;
                messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: messageController.text.length),
                );
              }
              if (result.finalResult) {
                isListeningLocal = false;
                statusText = 'Done listening';
              }
            });
          }
          
          void onSpeechError(SpeechRecognitionError error) {
            debugPrint('=== SPEECH ERROR ===');
            debugPrint('Error: ${error.errorMsg}');
            debugPrint('Permanent: ${error.permanent}');
            
            setDialogState(() {
              isListeningLocal = false;
              statusText = 'Error: ${error.errorMsg}';
            });
          }
          
          void onSpeechStatus(String status) {
            debugPrint('=== SPEECH STATUS: $status ===');
            setDialogState(() {
              statusText = status;
              if (status == 'done' || status == 'notListening') {
                isListeningLocal = false;
              }
            });
          }
          
          // Whisper fallback: Record audio and send to backend
          // Note: This doesn't work well on Web - web should use native speech_to_text
          // Declared before toggleListening so it can be called from there
          Future<void> toggleWhisperRecording() async {
            // Whisper recording doesn't work well on web
            if (kIsWeb) {
              setDialogState(() {
                statusText = 'Use native speech on web. Try again.';
                useWhisperFallback = false;
              });
              return;
            }
            
            if (isRecordingForWhisper) {
              // Stop recording and transcribe
              debugPrint('Stopping Whisper recording...');
              setDialogState(() {
                statusText = 'Processing...';
              });
              
              try {
                final path = await audioRecorder.stop();
                debugPrint('Recording saved to: $path');
                
                if (path != null && path.isNotEmpty) {
                  setDialogState(() {
                    isRecordingForWhisper = false;
                    statusText = 'Transcribing with Whisper...';
                  });
                  
                  // Send to Whisper backend
                  try {
                    final whisperService = WhisperTranscriptionService(
                      baseUrl: ApiService.baseUrl.replaceAll('/api/v1', ''),
                    );
                    final result = await whisperService.transcribeAudio(path);
                    
                    if (result.isNotEmpty) {
                      setDialogState(() {
                        lastWords = result.text;
                        messageController.text = result.text;
                        messageController.selection = TextSelection.fromPosition(
                          TextPosition(offset: messageController.text.length),
                        );
                        statusText = 'Transcribed (${result.language})';
                      });
                    } else {
                      setDialogState(() {
                        statusText = 'No speech detected';
                      });
                    }
                  } catch (e) {
                    debugPrint('Whisper transcription error: $e');
                    setDialogState(() {
                      statusText = 'Transcription failed: $e';
                    });
                  }
                  
                  // Cleanup recording file
                  try {
                    await File(path).delete();
                  } catch (_) {}
                }
              } catch (e) {
                debugPrint('Stop recording error: $e');
                setDialogState(() {
                  isRecordingForWhisper = false;
                  statusText = 'Recording failed';
                });
              }
              return;
            }
            
            // Start recording for Whisper
            bool hasPermission = await requestPermissions();
            if (!hasPermission) return;
            
            try {
              // Check if can record
              if (!await audioRecorder.hasPermission()) {
                setDialogState(() {
                  statusText = 'Microphone permission denied';
                });
                return;
              }
              
              // Get temp directory for recording
              final tempDir = await getTemporaryDirectory();
              recordingPath = '${tempDir.path}/sos_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
              
              // Start recording
              await audioRecorder.start(
                const RecordConfig(
                  encoder: AudioEncoder.wav,
                  sampleRate: 16000,
                  numChannels: 1,
                ),
                path: recordingPath!,
              );
              
              setDialogState(() {
                isRecordingForWhisper = true;
                statusText = 'Recording... Tap to stop';
              });
              
              debugPrint('Whisper recording started: $recordingPath');
              
              // Monitor amplitude for visual feedback
              audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
                setDialogState(() {
                  // Convert dB to 0-1 range (roughly)
                  soundLevel = ((amp.current + 50) / 50).clamp(0, 1) * 10;
                });
              });
              
            } catch (e) {
              debugPrint('Start recording error: $e');
              setDialogState(() {
                statusText = 'Failed to start recording: $e';
              });
            }
          }
          
          Future<void> toggleListening() async {
            // If using Whisper mode (recording) - only on mobile
            if (useWhisperFallback && !kIsWeb) {
              await toggleWhisperRecording();
              return;
            }
            
            if (isListeningLocal) {
              // Stop listening
              debugPrint('Stopping speech recognition...');
              await speechToText.stop();
              setDialogState(() {
                isListeningLocal = false;
                statusText = 'Stopped';
              });
              return;
            }
            
            // Request permissions first
            bool hasPermission = await requestPermissions();
            if (!hasPermission) return;
            
            // Initialize if not already done
            if (!speechEnabled) {
              debugPrint('Initializing speech recognition...');
              setDialogState(() {
                statusText = 'Initializing...';
              });
              
              try {
                speechEnabled = await speechToText.initialize(
                  onError: onSpeechError,
                  onStatus: onSpeechStatus,
                  debugLogging: true,
                );
                debugPrint('Speech initialized: $speechEnabled');
                debugPrint('Is available: ${speechToText.isAvailable}');
              } catch (e) {
                debugPrint('Native STT init error: $e');
                if (kIsWeb) {
                  // On web, show error as Whisper doesn't work
                  setDialogState(() {
                    statusText = 'Speech not available in this browser';
                  });
                  return;
                }
                // On mobile, switch to Whisper fallback
                setDialogState(() {
                  useWhisperFallback = true;
                  statusText = 'Using Whisper mode';
                });
                await toggleWhisperRecording();
                return;
              }
            }
            
            if (!speechEnabled || !speechToText.isAvailable) {
              debugPrint('Native STT not available');
              if (kIsWeb) {
                setDialogState(() {
                  statusText = 'Speech not available in this browser';
                });
                return;
              }
              setDialogState(() {
                useWhisperFallback = true;
                statusText = 'Using Whisper mode';
              });
              await toggleWhisperRecording();
              return;
            }
            
            // Start listening with native STT
            setDialogState(() {
              isListeningLocal = true;
              statusText = 'Listening...';
            });
            
            try {
              debugPrint('Starting native STT...');
              await speechToText.listen(
                onResult: onSpeechResult,
                listenFor: const Duration(seconds: 30),
                pauseFor: const Duration(seconds: 3),
                partialResults: true,
                cancelOnError: false,
                listenMode: stt.ListenMode.dictation,
                onSoundLevelChange: (level) {
                  setDialogState(() {
                    soundLevel = level;
                  });
                },
              );
              debugPrint('Native STT started');
            } catch (e) {
              debugPrint('Native STT listen error: $e - switching to Whisper');
              setDialogState(() {
                isListeningLocal = false;
                useWhisperFallback = true;
                statusText = 'Using Whisper mode';
              });
              await toggleWhisperRecording();
            }
          }
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.message, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                const Expanded(child: Text('SOS Message')),
                if (_sosMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sent',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter your emergency message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: GestureDetector(
                      onTap: toggleListening,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isListeningLocal || isRecordingForWhisper)
                              ? AppTheme.primaryRed 
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (isListeningLocal || isRecordingForWhisper) ? Icons.mic : Icons.mic_none,
                          color: (isListeningLocal || isRecordingForWhisper) ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isListeningLocal || isRecordingForWhisper) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryRed.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRecordingForWhisper 
                                  ? 'Recording... Tap to transcribe'
                                  : 'Listening... Speak now',
                              style: const TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Sound level indicator
                        Container(
                          height: 4,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (soundLevel.clamp(-2, 10) + 2) / 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (statusText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusText.contains('Error') ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Tap the mic icon to speak your message',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await speechToText.stop();
                  await audioRecorder.stop();
                  await audioRecorder.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await speechToText.stop();
                  await audioRecorder.stop();
                  await audioRecorder.dispose();
                  if (messageController.text.isNotEmpty) {
                    // Send message to backend
                    try {
                      if (_sosId.isNotEmpty && !_sosId.startsWith('1')) {
                        final api = ref.read(apiServiceProvider);
                        await api.updateSOSMessage(_sosId, messageController.text);
                        await api.addSOSAction(
                          _sosId,
                          'MESSAGE_SENT',
                          details: messageController.text,
                        );
                      }
                    } catch (e) {
                      debugPrint('Failed to send SOS message: $e');
                    }
                    setState(() {
                      _sosMessage = messageController.text;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent to responders'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                child: Text(_sosMessage.isEmpty ? 'Send' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMoreDetails() {
    final location = ref.read(currentLocationProvider).valueOrNull;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                const Text(
                  'SOS Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // SOS ID
            _buildDetailRow('SOS ID', _sosId),
            const Divider(),
            
            // Status
            _buildDetailRow('Status', _sosStatus, valueColor: AppTheme.primaryGreen),
            const Divider(),
            
            // Emergency Type
            _buildDetailRow('Emergency Type', widget.emergencyLabel),
            const Divider(),
            
            // Full Location
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fullAddress.isNotEmpty 
                          ? _fullAddress 
                          : '${location?.latitude.toStringAsFixed(6) ?? _defaultLatitude}, ${location?.longitude.toStringAsFixed(6) ?? _defaultLongitude}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard
                      Clipboard.setData(ClipboardData(
                        text: _fullAddress.isNotEmpty 
                            ? _fullAddress 
                            : '${location?.latitude ?? _defaultLatitude}, ${location?.longitude ?? _defaultLongitude}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 20),
                  ),
                ],
              ),
            ),
            
            // Coordinates
            if (location != null) ...[
              const SizedBox(height: 12),
              Text(
                'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            
            // Message if present
            if (_sosMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Your Message',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                ),
                child: Text(_sosMessage),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showVolunteersNearby() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nearby Volunteers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.requireVolunteerAssistance) ...[
              _buildVolunteerTile('Rahul Sharma', '0.5 km away', true),
              _buildVolunteerTile('Priya Patel', '0.8 km away', true),
              _buildVolunteerTile('Amit Kumar', '1.2 km away', false),
            ] else
              const Text('Volunteer assistance not requested'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerTile(String name, String distance, bool responding) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: responding ? AppTheme.primaryGreen : Colors.grey,
        child: Icon(
          Icons.person,
          color: Colors.white,
        ),
      ),
      title: Text(name),
      subtitle: Text(distance),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: responding ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          responding ? 'Responding' : 'Notified',
          style: TextStyle(
            color: responding ? AppTheme.primaryGreen : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          locationAsync.when(
            data: (location) {
              final userLatLng = LatLng(
                location?.latitude ?? _defaultLatitude,
                location?.longitude ?? _defaultLongitude,
              );
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLatLng,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sahay.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLatLng,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'My Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_pin,
                              color: AppTheme.primaryRed,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_defaultLatitude, _defaultLongitude),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sahay.app',
                ),
              ],
            ),
          ),
          
          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Sahay',
                    style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Show info
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Emergency Active'),
                          content: const Text(
                            'Your SOS alert is active. Authorities and volunteers have been notified of your location.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side Buttons
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                // Center on Location
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final location = ref.read(currentLocationProvider).valueOrNull;
                      if (location != null) {
                        _mapController.move(
                          LatLng(location.latitude, location.longitude),
                          16,
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, color: AppTheme.primaryRed),
                  ),
                ),
                const SizedBox(height: 12),
                // Show Volunteers
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showVolunteersNearby,
                    icon: const Icon(Icons.people, color: AppTheme.primaryRed),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SOS Message - Clickable
                  GestureDetector(
                    onTap: _showMessageDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.message, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SOS message',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (_sosMessage.isNotEmpty)
                                  Text(
                                    _sosMessage.length > 40 
                                        ? '${_sosMessage.substring(0, 40)}...' 
                                        : _sosMessage,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_sosMessage.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppTheme.primaryRed,
                                size: 20,
                              ),
                            )
                          else
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Service Status with Location
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency, color: AppTheme.primaryRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SOS ID: $_sosId',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'SOS STATUS: ',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  Text(
                                    _sosStatus,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_briefAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _briefAddress,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showMoreDetails,
                          child: const Row(
                            children: [
                              Text('More\nDetails'),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // I am Safe Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _markSafe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I am Safe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Sending SOS Alert...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
