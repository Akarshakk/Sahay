import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';

/// Reusable document upload widget for identity verification
class DocumentUploadWidget extends StatefulWidget {
  final Function(String? url, String? type) onDocumentUploaded;
  final String? initialUrl;
  final String? initialType;
  final Color accentColor;
  final bool required;
  final String? username; // For naming uploaded files

  const DocumentUploadWidget({
    super.key,
    required this.onDocumentUploaded,
    this.initialUrl,
    this.initialType,
    this.accentColor = AppTheme.primaryRed,
    this.required = false,
    this.username,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  File? _documentFile;
  Uint8List? _documentBytes; // For web compatibility
  String? _documentUrl;
  String _selectedDocumentType = 'aadhaar';
  bool _isUploading = false;

  final List<Map<String, String>> _documentTypes = [
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'pan', 'label': 'PAN Card'},
    {'value': 'driving_license', 'label': 'Driving License'},
    {'value': 'voter_id', 'label': 'Voter ID'},
  ];

  @override
  void initState() {
    super.initState();
    _documentUrl = widget.initialUrl;
    _selectedDocumentType = widget.initialType ?? 'aadhaar';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Identity Document',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralGray,
              ),
            ),
            if (widget.required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload Government ID',
          style: TextStyle(
            color: AppTheme.neutralGray.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        // Document Type Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDocumentType,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.description_outlined, color: widget.accentColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _documentTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDocumentType = value);
                widget.onDocumentUploaded(_documentUrl, value);
              }
            },
          ),
        ),

        const SizedBox(height: 16),

        // Upload Area
        InkWell(
          onTap: _isUploading ? null : _pickDocument,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _documentUrl != null 
                    ? AppTheme.primaryGreen 
                    : AppTheme.neutralGray.withValues(alpha: 0.2),
                width: _documentUrl != null ? 2 : 1,
              ),
            ),
            child: _isUploading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: widget.accentColor),
                        const SizedBox(height: 12),
                        const Text('Uploading document...'),
                      ],
                    ),
                  )
                : _documentBytes != null
                    ? Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _documentBytes!,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Uploaded', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _clearDocument,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppTheme.neutralGray.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload document',
                            style: TextStyle(
                              color: AppTheme.neutralGray.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              color: AppTheme.neutralGray.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  void _clearDocument() {
    setState(() {
      _documentFile = null;
      _documentBytes = null;
      _documentUrl = null;
    });
    widget.onDocumentUploaded(null, null);
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    
    // On web, camera is not supported, so go directly to gallery
    ImageSource? source;
    
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Document Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: widget.accentColor),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a photo of your document'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: widget.accentColor),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      
      setState(() {
        _documentBytes = bytes;
        _documentFile = kIsWeb ? null : File(image.path);
        _isUploading = true;
      });

      // Upload to Backend Server (Local Storage)
      final queryParams = {
        'username': widget.username ?? 'user',
        'documentType': _selectedDocumentType,
      };
      final uri = Uri.parse('http://localhost:3000/api/v1/upload').replace(queryParameters: queryParams);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 201) {
        throw Exception('Upload failed: ${response.body}');
      }
      
      final responseData = json.decode(response.body);
      final downloadUrl = responseData['url'] as String;

      setState(() {
        _documentUrl = downloadUrl;
        _isUploading = false;
      });

      widget.onDocumentUploaded(downloadUrl, _selectedDocumentType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _documentFile = null;
        _documentUrl = null;
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }
}
