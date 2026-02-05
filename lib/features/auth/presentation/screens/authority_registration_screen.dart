import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Authority Registration Screen
/// Receives phoneNumber and authorityCodeData from OTP verification
class AuthorityRegistrationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic> authorityCodeData;
  final String? verifiedEmail;

  const AuthorityRegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.authorityCodeData,
    this.verifiedEmail,
  });

  @override
  ConsumerState<AuthorityRegistrationScreen> createState() =>
      _AuthorityRegistrationScreenState();
}

class _AuthorityRegistrationScreenState
    extends ConsumerState<AuthorityRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Document upload
  File? _idDocumentFile;
  String? _idDocumentUrl;
  String _selectedDocumentType = 'aadhaar';
  bool _isUploadingDocument = false;

  final List<Map<String, String>> _documentTypes = [
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'pan', 'label': 'PAN Card'},
    {'value': 'driving_license', 'label': 'Driving License'},
    {'value': 'voter_id', 'label': 'Voter ID'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.verifiedEmail != null) {
      _emailController.text = widget.verifiedEmail!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Authority Registration',
          style: TextStyle(
            color: AppTheme.neutralGray,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Authority Info Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.authorityAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.authorityAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Verified: ${widget.authorityCodeData['code']}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.authorityCodeData['department']} • ${widget.authorityCodeData['area']}',
                        style: TextStyle(
                          color: AppTheme.neutralGray.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: +91 ${widget.phoneNumber}',
                        style: TextStyle(
                          color: AppTheme.neutralGray.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Form Title
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // Full Name
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Registration Number
                _buildTextField(
                  controller: _regNumberController,
                  label: 'Government ID / Registration Number',
                  hint: 'e.g., BADGE-12345',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your registration number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralGray.withValues(alpha: 0.5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // Confirm Password
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralGray.withValues(alpha: 0.5),
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 24),

                // Document Upload Section
                const Text(
                  'Identity Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your government ID for verification',
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined, color: AppTheme.authorityAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      }
                    },
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                // Document Upload Area
                InkWell(
                  onTap: _isUploadingDocument ? null : _pickDocument,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _idDocumentFile != null 
                            ? AppTheme.primaryGreen 
                            : AppTheme.neutralGray.withValues(alpha: 0.2),
                        width: _idDocumentFile != null ? 2 : 1,
                      ),
                    ),
                    child: _isUploadingDocument
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.authorityAccent),
                                SizedBox(height: 12),
                                Text('Uploading document...'),
                              ],
                            ),
                          )
                        : _idDocumentFile != null
                            ? Stack(
                                children: [
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _idDocumentFile!,
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
                                          onTap: () => setState(() {
                                            _idDocumentFile = null;
                                            _idDocumentUrl = null;
                                          }),
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
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.authorityAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'COMPLETE REGISTRATION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.authorityAccent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.authorityAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryRed),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    
    // Show bottom sheet to choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
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
                leading: const Icon(Icons.camera_alt, color: AppTheme.authorityAccent),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo of your document'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.authorityAccent),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _idDocumentFile = File(image.path);
        _isUploadingDocument = true;
      });

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('identity_documents')
          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');

      final uploadTask = storageRef.putFile(_idDocumentFile!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _idDocumentUrl = downloadUrl;
        _isUploadingDocument = false;
      });

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
        _idDocumentFile = null;
        _idDocumentUrl = null;
        _isUploadingDocument = false;
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

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idDocumentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your identity document'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = ref.read(authControllerProvider.notifier);
      
      final user = await authController.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: widget.phoneNumber,
        role: UserRole.authority,
        address: widget.authorityCodeData['area'] ?? '',
        profession: widget.authorityCodeData['department'] ?? '',
        dob: DateTime.now(), // Authority registration doesn't require DOB
        registeredArea: widget.authorityCodeData['area'],
        registeredAreaId: widget.authorityCodeData['areaId'],
        identityDocumentUrl: _idDocumentUrl,
        identityDocumentType: _selectedDocumentType,
        authorityCode: widget.authorityCodeData['code'],
        department: widget.authorityCodeData['department'],
        registrationNumber: _regNumberController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen(userRole: UserRole.authority)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
