import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/profile_provider.dart';
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
    final user = ref.read(authControllerProvider);
    final profileData = ref.read(profileProvider);

    if (user != null) {
      // Use saved profile data if available, otherwise use auth data
      _nameController.text =
          profileData.name.isNotEmpty ? profileData.name : user.name;
      _phoneController.text =
          profileData.phone.isNotEmpty ? profileData.phone : user.phone;
      _emailController.text =
          profileData.email.isNotEmpty ? profileData.email : '';
      _professionController.text = profileData.profession;
      _addressController.text = profileData.address;
      _profileImagePath = profileData.profileImagePath;

      // Initialize provider from user if first load
      if (profileData.name.isEmpty) {
        ref.read(profileProvider.notifier).updateProfile(
              name: user.name,
              phone: user.phone,
            );
      }
    }
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
        // Geocoding may fail on web or emulator - that's okay
        _currentAddress = null;
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
                      value: profileData.email.isNotEmpty
                          ? profileData.email
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
                      value: profileData.profession.isNotEmpty
                          ? profileData.profession
                          : 'Not set',
                      icon: Icons.work,
                    ),

              const SizedBox(height: 16),

              // Address
              _isEditing
                  ? _buildEditableField(
                      controller: _addressController,
                      label: 'Home Address',
                      icon: Icons.home,
                      maxLines: 2,
                    )
                  : _buildInfoTile(
                      label: 'Home Address',
                      value: profileData.address.isNotEmpty
                          ? profileData.address
                          : 'Not set',
                      icon: Icons.home,
                    ),

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

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📷 Image picker coming soon!'),
        backgroundColor: AppTheme.primaryOrange,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save to provider (with persistence)
    await ref.read(profileProvider.notifier).updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          profession: _professionController.text,
          address: _addressController.text,
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
