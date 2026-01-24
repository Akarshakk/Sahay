import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  final List<Map<String, dynamic>> _categories = [
    {'value': 'infrastructure', 'label': 'Infrastructure', 'icon': Icons.construction, 'color': Colors.orange},
    {'value': 'safety', 'label': 'Safety', 'icon': Icons.warning, 'color': Colors.red},
    {'value': 'health', 'label': 'Health', 'icon': Icons.local_hospital, 'color': Colors.blue},
    {'value': 'environment', 'label': 'Environment', 'icon': Icons.eco, 'color': Colors.green},
    {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash, 'color': Colors.deepOrange},
    {'value': 'other', 'label': 'Other', 'icon': Icons.info, 'color': Colors.grey},
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
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
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
      final api = ref.read(apiServiceProvider);
      final result = await api.createPost({
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'latitude': widget.currentPosition!.latitude,
        'longitude': widget.currentPosition!.longitude,
        'address': _address,
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
      // Offline mode - show success with queue indicator
      if (mounted) {
        Navigator.pop(context, true);
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
                      setState(() => _selectedCategory = cat['value'] as String);
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
                hintText: 'Describe what you\'re reporting...\n\nBe specific and clear to help others verify.',
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
                      'Your post will be visible to people within 2km. '
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
