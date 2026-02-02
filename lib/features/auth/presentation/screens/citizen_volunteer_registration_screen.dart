import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../providers/auth_provider.dart';

/// Citizen/Volunteer Registration Form Screen
class CitizenVolunteerRegistrationScreen extends ConsumerStatefulWidget {
  final UserRole userRole;
  final String phoneNumber;
  final String? verifiedEmail;

  const CitizenVolunteerRegistrationScreen({
    super.key,
    required this.userRole,
    required this.phoneNumber,
    this.verifiedEmail,
  });

  @override
  ConsumerState<CitizenVolunteerRegistrationScreen> createState() =>
      _CitizenVolunteerRegistrationScreenState();
}

class _CitizenVolunteerRegistrationScreenState
    extends ConsumerState<CitizenVolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Volunteer area selection
  String? _selectedArea;
  String? _selectedAreaId;
  List<Map<String, dynamic>> _availableAreas = [];

  // Document upload
  String? _documentUrl;
  String? _documentType;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber.isNotEmpty) {
      _phoneController.text = widget.phoneNumber;
    }
    if (widget.verifiedEmail != null) {
      _emailController.text = widget.verifiedEmail!;
    }
    // Load available areas for volunteers
    if (widget.userRole == UserRole.volunteer) {
      _loadAvailableAreas();
    }
  }

  Future<void> _loadAvailableAreas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('area_resources')
          .get();
      if (mounted) {
        setState(() {
          _availableAreas = snapshot.docs.map((doc) => {
            'areaId': doc.id,
            'areaName': doc.data()['areaName'] ?? doc.id,
          }).toList();
        });
      }
    } catch (e) {
      // Fallback areas if Firestore fails
      _availableAreas = [
        {'areaId': 'mumbai-central', 'areaName': 'Mumbai Central'},
        {'areaId': 'delhi-south', 'areaName': 'Delhi South'},
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _professionController.dispose();
    _addressController.dispose();
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
        title: Text(
          widget.userRole == UserRole.citizen
              ? 'Citizen Registration'
              : 'Volunteer Registration',
          style: const TextStyle(
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
                const SizedBox(height: 20),

                // Role Badge
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent.withValues(alpha: 0.1)
                          : AppTheme.volunteerAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.userRole == UserRole.citizen
                            ? AppTheme.citizenAccent
                            : AppTheme.volunteerAccent,
                      ),
                    ),
                    child: Text(
                      widget.userRole == UserRole.citizen
                          ? 'CITIZEN'
                          : 'VOLUNTEER',
                      style: TextStyle(
                        color: widget.userRole == UserRole.citizen
                            ? AppTheme.citizenAccent
                            : AppTheme.volunteerAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 32),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon:
                        const Icon(Icons.phone, color: AppTheme.neutralGray),
                    prefixText: '+91 ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.length != 10) {
                      return 'Mobile number must be 10 digits';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    prefixIcon:
                        const Icon(Icons.person, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Enter your email address',
                    prefixIcon:
                        const Icon(Icons.email, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Create a password (min 6 characters)',
                    prefixIcon:
                        const Icon(Icons.lock, color: AppTheme.primaryRed),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.neutralGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
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
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.primaryRed),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.neutralGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Date of Birth
                InkWell(
                  onTap: _isLoading ? null : _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      hintText: 'Select your date of birth',
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryRed, width: 2),
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppTheme.neutralGray.withValues(alpha: 0.5)
                            : AppTheme.neutralGray,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Profession
                TextFormField(
                  controller: _professionController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Profession *',
                    hintText: 'Enter your profession',
                    prefixIcon:
                        const Icon(Icons.work, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your profession';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Volunteer Area Selection (only for volunteers)
                if (widget.userRole == UserRole.volunteer) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedArea != null 
                            ? AppTheme.volunteerAccent 
                            : AppTheme.neutralGray.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAreaId,
                      decoration: const InputDecoration(
                        labelText: 'Select Area *',
                        hintText: 'Choose your volunteer area',
                        prefixIcon: Icon(Icons.map, color: AppTheme.volunteerAccent),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _availableAreas.isEmpty
                          ? [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Loading areas...'),
                              ),
                            ]
                          : _availableAreas.map((area) {
                              return DropdownMenuItem(
                                value: area['areaId'] as String,
                                child: Text(area['areaName'] as String),
                              );
                            }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final area = _availableAreas.firstWhere(
                            (a) => a['areaId'] == value,
                            orElse: () => {'areaId': value, 'areaName': value},
                          );
                          setState(() {
                            _selectedAreaId = value;
                            _selectedArea = area['areaName'] as String;
                          });
                        }
                      },
                      validator: (value) {
                        if (widget.userRole == UserRole.volunteer && value == null) {
                          return 'Please select your volunteer area';
                        }
                        return null;
                      },
                    ),
                  ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 20),
                ],

                // Address
                TextFormField(
                  controller: _addressController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Enter your complete address',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child:
                          Icon(Icons.location_on, color: AppTheme.primaryRed),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    if (value.length < 10) {
                      return 'Please enter a complete address';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Document Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent.withValues(alpha: 0.3)
                          : AppTheme.volunteerAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DocumentUploadWidget(
                    accentColor: widget.userRole == UserRole.citizen
                        ? AppTheme.citizenAccent
                        : AppTheme.volunteerAccent,
                    required: false,
                    onDocumentUploaded: (url, type) {
                      setState(() {
                        _documentUrl = url;
                        _documentType = type;
                      });
                    },
                  ),
                ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent
                          : AppTheme.volunteerAccent,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
                ).animate().fadeIn(delay: 600.ms).scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.userRole == UserRole.citizen
                  ? AppTheme.citizenAccent
                  : AppTheme.volunteerAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            role: widget.userRole == UserRole.citizen ? 'citizen' : 'volunteer',
            address: _addressController.text,
            profession: _professionController.text,
            dob: _selectedDate!,
            // Volunteer area assignment
            registeredArea: widget.userRole == UserRole.volunteer ? _selectedArea : null,
            registeredAreaId: widget.userRole == UserRole.volunteer ? _selectedAreaId : null,
            // Identity document (optional for citizen/volunteer)
            identityDocumentUrl: _documentUrl,
            identityDocumentType: _documentType,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.userRole == UserRole.citizen
                ? 'Citizen registration successful!'
                : 'Volunteer registration successful!',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      // Navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userRole: widget.userRole),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Check for specific error types
      String errorMessage = 'Registration Failed';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('409') ||
          errorString.contains('conflict') ||
          errorString.contains('already exists') ||
          errorString.contains('already registered')) {
        errorMessage =
            'This email is already registered. Please use a different email or login instead.';
      } else if (errorString.contains('400') ||
          errorString.contains('bad request')) {
        errorMessage = 'Please check your information and try again.';
      } else if (errorString.contains('network') ||
          errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Registration failed. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
