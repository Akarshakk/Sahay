import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Profile Screen - Edit user details with persistence
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();
  final _registeredAreaController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();

  String? _profileImagePath;
  String? _currentLocation;
  String? _currentAddress;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _fetchCurrentLocation();
    });
  }

  void _loadUserData() {
    final authUser = ref.read(authControllerProvider);
    final profileData = ref.read(profileProvider);
    
    // Use authUser if available, otherwise fall back to mock user (like drawer does)
    final user = authUser ?? MockUsers.citizen;

    // Use auth data for all fields since it comes from database after login
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    
    // Use user data if available, fallback to profile provider for any missing
    _emailController.text = user.email ?? profileData.email;
    _professionController.text = user.profession ?? profileData.profession;
    _addressController.text = user.address ?? profileData.address;
    _registeredAreaController.text = user.registeredArea ?? '';
    _stateController.text = user.state ?? profileData.state;
    _districtController.text = user.district ?? profileData.district;
    _cityController.text = user.city ?? profileData.city;
    _profileImagePath = profileData.profileImagePath;

    // Sync profile provider with current user data
    ref.read(profileProvider.notifier).initFromUser(
          user.name,
          user.email ?? profileData.email,
          user.phone,
        );
    
    setState(() {});
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services disabled';
          _fetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission denied';
          _fetchingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _currentLocation =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      // Get address from coordinates (may fail on web/emulator)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            parts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            parts.add(place.administrativeArea!);
          }
          _currentAddress = parts.isNotEmpty ? parts.join(', ') : null;
        }
      } catch (e) {
        // Geocoding may fail on web or emulator - show fallback message
        _currentAddress = 'Address lookup unavailable';
        print('Geocoding error: $e');
      }
    } catch (e) {
      _currentLocation = 'Could not get location';
    }

    setState(() => _fetchingLocation = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _addressController.dispose();
    _registeredAreaController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final profileData = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryRed),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                        backgroundImage: _profileImagePath != null
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: _profileImagePath == null
                            ? Text(
                                (profileData.name.isNotEmpty
                                        ? profileData.name
                                        : user?.name ?? 'A')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 12),

              // User Role Badge
              if (user != null)
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getRoleColors(user.role.name),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getRoleColors(user.role.name)
                              .first
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(user.role.name),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // Current Location Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryRed.withOpacity(0.1),
                      AppTheme.primaryOrange.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location,
                            color: AppTheme.primaryRed, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                        const Spacer(),
                        if (_fetchingLocation)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _fetchCurrentLocation,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_currentAddress != null && _currentAddress!.isNotEmpty)
                      Text(
                        _currentAddress!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    if (_currentLocation != null)
                      Text(
                        'Coordinates: $_currentLocation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutralGray.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Full Name
              _isEditing
                  ? _buildEditableField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter your name'
                          : null,
                    )
                  : _buildInfoTile(
                      label: 'Full Name',
                      value: profileData.name.isNotEmpty
                          ? profileData.name
                          : 'Not set',
                      icon: Icons.person,
                    ),

              const SizedBox(height: 16),

              // Phone Number (Now Editable)
              _isEditing
                  ? _buildEditableField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter phone number'
                          : null,
                    )
                  : _buildInfoTile(
                      label: 'Phone Number',
                      value: profileData.phone.isNotEmpty
                          ? '+91 ${profileData.phone}'
                          : 'Not set',
                      icon: Icons.phone,
                    ),

              const SizedBox(height: 16),

              // Email
              _isEditing
                  ? _buildEditableField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    )
                  : _buildInfoTile(
                      label: 'Email Address',
                      value: (user?.email ?? profileData.email).isNotEmpty
                          ? (user?.email ?? profileData.email)
                          : 'Not set',
                      icon: Icons.email,
                    ),

              const SizedBox(height: 16),

              // Profession
              _isEditing
                  ? _buildEditableField(
                      controller: _professionController,
                      label: 'Profession',
                      icon: Icons.work,
                    )
                  : _buildInfoTile(
                      label: 'Profession',
                      value: (user?.profession ?? profileData.profession).isNotEmpty
                          ? (user?.profession ?? profileData.profession)
                          : 'Not set',
                      icon: Icons.work,
                    ),

              const SizedBox(height: 16),

              _isEditing
                  ? _buildEditableField(
                      controller: _addressController,
                      label: 'Home Address',
                      icon: Icons.home,
                      maxLines: 2,
                    )
                  : _buildInfoTile(
                      label: 'Home Address',
                      value: (user?.address ?? profileData.address).isNotEmpty
                          ? (user?.address ?? profileData.address)
                          : 'Not set',
                      icon: Icons.home,
                    ),

              const SizedBox(height: 16),

              // State
              _isEditing
                  ? _buildEditableField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map,
                    )
                  : _buildInfoTile(
                      label: 'State',
                      value: (user?.state ?? profileData.state).isNotEmpty
                          ? (user?.state ?? profileData.state)
                          : 'Not set',
                      icon: Icons.map,
                    ),

              const SizedBox(height: 16),

              // District
              _isEditing
                  ? _buildEditableField(
                      controller: _districtController,
                      label: 'District',
                      icon: Icons.location_city,
                    )
                  : _buildInfoTile(
                      label: 'District',
                      value: (user?.district ?? profileData.district).isNotEmpty
                          ? (user?.district ?? profileData.district)
                          : 'Not set',
                      icon: Icons.location_city,
                    ),

              const SizedBox(height: 16),

              // City
              _isEditing
                  ? _buildEditableField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_on,
                    )
                  : _buildInfoTile(
                      label: 'City',
                      value: (user?.city ?? profileData.city).isNotEmpty
                          ? (user?.city ?? profileData.city)
                          : 'Not set',
                      icon: Icons.location_on,
                    ),

              const SizedBox(height: 24),

              // My Documents Section
              _buildDocumentsSection(user),

              if (_isEditing) ...[
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primaryRed.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'SAVE CHANGES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _loadUserData();
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neutralGray,
                      side: BorderSide(
                          color: AppTheme.neutralGray.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.neutralGray.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppTheme.primaryRed),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.neutralGray.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralGray.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutralGray.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        value == 'Not set' ? Colors.grey : AppTheme.neutralGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildDocumentsSection(User? user) {
    final hasDocument = user?.identityDocumentUrl != null && user!.identityDocumentUrl!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_copy, color: AppTheme.primaryRed, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'My Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasDocument) ...[
            // Show uploaded document
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDocumentType(user.identityDocumentType ?? 'Document'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Uploaded & Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppTheme.primaryRed),
                    onPressed: () => _viewDocument(user.identityDocumentUrl!),
                    tooltip: 'View Document',
                  ),
                ],
              ),
            ),
          ] else ...[
            // No document uploaded
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No documents uploaded yet',
                      style: TextStyle(
                        color: AppTheme.neutralGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Upload/Update button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDocumentUploadDialog,
              icon: Icon(hasDocument ? Icons.refresh : Icons.upload_file),
              label: Text(hasDocument ? 'Update Document' : 'Upload Document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  String _formatDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'aadhaar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'driving_license':
        return 'Driving License';
      case 'voter_id':
        return 'Voter ID';
      default:
        return type;
    }
  }

  void _viewDocument(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Document Preview'),
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
                        const SizedBox(height: 8),
                        Text('Could not load image\n$url', textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentUploadDialog() {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: DocumentUploadWidget(
                  initialUrl: user.identityDocumentUrl,
                  initialType: user.identityDocumentType,
                  username: user.phone, // Use phone as username for uniqueness
                  onDocumentUploaded: (url, type) async {
                    if (url != null && type != null) {
                      try {
                        // Update user profile with new document
                        await ref.read(authControllerProvider.notifier).updateUser({
                          'identityDocumentUrl': url,
                          'identityDocumentType': type,
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document updated successfully!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                          // Reload profile to refresh UI
                          setState(() {
                            _loadUserData();
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update profile: $e'),
                              backgroundColor: AppTheme.primaryRed,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // On web, go directly to gallery. On mobile, show camera/gallery choice.
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
                    'Select Profile Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: AppTheme.primaryRed),
                    title: const Text('Camera'),
                    subtitle: const Text('Take a new photo'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: AppTheme.primaryRed),
                    title: const Text('Gallery'),
                    subtitle: const Text('Choose from files'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _profileImagePath = image.path;
      });
      
      // Save to profile provider
      ref.read(profileProvider.notifier).setProfileImage(image.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile photo updated!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save to backend first
    try {
      await ref.read(authControllerProvider.notifier).updateUser({
        'fullName': _nameController.text,
        'phone': _phoneController.text,
        // Email cannot be updated directly via this endpoint
        'profession': _professionController.text,
        'address': _addressController.text,
        'state': _stateController.text,
        'district': _districtController.text,
        'city': _cityController.text,
        'registeredArea': _cityController.text, // Use city as registered area
      });

      // Then save to local provider (with persistence)
      await ref.read(profileProvider.notifier).updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            profession: _professionController.text,
            address: _addressController.text,
            stateVal: _stateController.text,
            district: _districtController.text,
            city: _cityController.text,
            profileImagePath: _profileImagePath,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile saved successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  List<Color> _getRoleColors(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return [AppTheme.primaryGreen, const Color(0xFF00BFA5)];
      case 'volunteer':
        return [AppTheme.primaryOrange, const Color(0xFFFF8A65)];
      case 'authority':
        return [AppTheme.primaryRed, const Color(0xFFE53935)];
      default:
        return [AppTheme.neutralGray, AppTheme.neutralGray];
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return Icons.person;
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'authority':
        return Icons.security;
      default:
        return Icons.badge;
    }
  }
}
