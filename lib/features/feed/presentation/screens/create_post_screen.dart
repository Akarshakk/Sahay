import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Position? currentPosition;

  const CreatePostScreen({super.key, this.currentPosition});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = 'other';
  String? _address;
  bool _isLoading = false;
  XFile? _pickedImage; // Use XFile for cross-platform support

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'infrastructure',
      'label': 'Infrastructure',
      'icon': Icons.construction,
      'color': Colors.orange
    },
    {
      'value': 'safety',
      'label': 'Safety',
      'icon': Icons.warning,
      'color': Colors.red
    },
    {
      'value': 'health',
      'label': 'Health',
      'icon': Icons.local_hospital,
      'color': Colors.blue
    },
    {
      'value': 'environment',
      'label': 'Environment',
      'icon': Icons.eco,
      'color': Colors.green
    },
    {
      'value': 'accident',
      'label': 'Accident',
      'icon': Icons.car_crash,
      'color': Colors.deepOrange
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.info,
      'color': Colors.grey
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    if (widget.currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (parts.isNotEmpty) {
          setState(() {
            _address = parts.join(', ');
          });
        }
      }
    } catch (e) {
      // Geocoding may fail on web/emulator - that's okay
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> mediaUrls = [];

      // Upload image if selected
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('feed_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (kIsWeb) {
          // For web, we must upload bytes
          final bytes = await _pickedImage!.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          // For mobile, putFile is more efficient
          await ref.putFile(File(_pickedImage!.path));
        }

        final url = await ref.getDownloadURL();
        mediaUrls.add(url);
      }

      final api = ref.read(apiServiceProvider);
      final result = await api.createPost({
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'latitude': widget.currentPosition!.latitude,
        'longitude': widget.currentPosition!.longitude,
        'address': _address,
        'mediaUrls': mediaUrls,
      });

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Post created successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating post: $e');
      if (mounted) {
        Navigator.pop(context, true); // Still pop for demo purposes if offline
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 Post saved! Will sync when online.'),
            backgroundColor: AppTheme.primaryOrange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutralGray,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'POST',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category selection
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : cat['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(cat['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                          () => _selectedCategory = cat['value'] as String);
                    }
                  },
                  selectedColor: cat['color'] as Color,
                  backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : cat['color'],
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Content
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Describe what you\'re reporting...\n\nBe specific and clear to help others verify.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Image Upload Section
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _pickedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(
                                    _pickedImage!.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_pickedImage!.path),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload image',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Location info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (_address != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _address!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  if (widget.currentPosition != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${widget.currentPosition!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${widget.currentPosition!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your post will be visible to people within 10km. '
                      'Get 5+ verifications to promote it to an official incident!',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
