import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import 'citizen_volunteer_registration_screen.dart';
import 'authority_registration_screen.dart';
import '../providers/auth_provider.dart';

/// Email Verification Screen
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final UserRole userRole;

  const OtpVerificationScreen({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authorityCodeController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  int _resendTimer = 30;

  // Authority code validation result
  Map<String, dynamic>? _validatedAuthorityCode;
  String? _authorityCodeError;
  bool _isAuthority = false;

  @override
  void initState() {
    super.initState();
    _isAuthority = widget.userRole == UserRole.authority;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authorityCodeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isAuthority
                        ? AppTheme.authorityAccent.withValues(alpha: 0.1)
                        : AppTheme.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: _isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed,
                    ),
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 24),

                // Title
                Text(
                  _otpSent ? 'Verify OTP' : 'Enter Email Address',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  _otpSent
                      ? 'Enter the 6-digit code sent to ${_emailController.text}'
                      : _isAuthority 
                          ? 'Enter your department email and authority code'
                          : 'We\'ll send a verification code to your email',
                   textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                if (!_otpSent) ...[
                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'john@example.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: _isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed,
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
                        borderSide: BorderSide(
                            color: _isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  // Authority Code Input (only for authority role)
                  if (_isAuthority) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _authorityCodeController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Authority Code *',
                        hintText: 'e.g., POLICE-MUM-001',
                        prefixIcon: const Icon(Icons.security, color: AppTheme.authorityAccent),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _authorityCodeError,
                        helperText: _validatedAuthorityCode != null 
                            ? '✓ ${_validatedAuthorityCode!['department']} - ${_validatedAuthorityCode!['area']}'
                            : null,
                        helperStyle: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _validatedAuthorityCode != null 
                                  ? AppTheme.primaryGreen 
                                  : AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.authorityAccent, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        // Clear previous validation
                        if (_validatedAuthorityCode != null || _authorityCodeError != null) {
                          setState(() {
                            _validatedAuthorityCode = null;
                            _authorityCodeError = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (_isAuthority && (value == null || value.isEmpty)) {
                          return 'Please enter your authority code';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    // Validate Authority Code Button
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _validateAuthorityCode,
                        icon: const Icon(Icons.verified_user, size: 20),
                        label: Text(_validatedAuthorityCode != null ? 'CODE VERIFIED' : 'VERIFY CODE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _validatedAuthorityCode != null 
                              ? AppTheme.primaryGreen 
                              : AppTheme.authorityAccent,
                          side: BorderSide(
                            color: _validatedAuthorityCode != null 
                                ? AppTheme.primaryGreen 
                                : AppTheme.authorityAccent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ] else ...[
                  // OTP Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            counterText: '',
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
                              borderSide: BorderSide(
                                  color: _isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                            if (index == 5 && value.isNotEmpty) {
                              // Optional: auto-submit
                            }
                          },
                        ),
                      );
                    }).animate(interval: 50.ms).fadeIn().scale(),
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP
                  Center(
                    child: TextButton(
                      onPressed: _resendTimer == 0 ? _resendOtp : null,
                      child: Text(
                        _resendTimer > 0
                            ? 'Resend OTP in $_resendTimer seconds'
                            : 'Resend OTP',
                        style: TextStyle(
                          color: _resendTimer > 0
                              ? AppTheme.neutralGray.withValues(alpha: 0.5)
                              : (_isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAuthority ? AppTheme.authorityAccent : AppTheme.primaryRed,
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
                        : Text(
                            _otpSent ? 'VERIFY & CONTINUE' : 'SEND EMAIL OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                // Info box for authority
                if (_isAuthority && !_otpSent) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Authority codes are provided by your department. Contact your supervisor if you don\'t have one.',
                            style: TextStyle(
                              color: AppTheme.neutralGray,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Validate authority code against Firestore
  Future<void> _validateAuthorityCode() async {
    final code = _authorityCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _authorityCodeError = 'Please enter authority code');
      return;
    }

    setState(() {
      _isLoading = true;
      _authorityCodeError = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('authority_codes').doc(code).get();
      
      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          _authorityCodeError = 'Invalid authority code';
          _validatedAuthorityCode = null;
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      if (data['isActive'] != true) {
         setState(() {
          _authorityCodeError = 'Authority code is inactive';
          _validatedAuthorityCode = null;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _validatedAuthorityCode = {
          'code': code,
          'department': data['department'],
          'area': data['area'],
          'areaId': data['areaId'],
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _authorityCodeError = 'Error validating code';
      });
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isAuthority && _validatedAuthorityCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your authority code first'), backgroundColor: AppTheme.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.sendEmailOtp(email);

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _resendTimer = 30;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to email!'), backgroundColor: AppTheme.primaryGreen),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP'), backgroundColor: AppTheme.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.verifyEmailOtp(email, otp);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToNextScreen();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed),
      );
    }
  }

  void _navigateToNextScreen() {
    final email = _emailController.text.trim();
    if (_isAuthority) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AuthorityRegistrationScreen(
            phoneNumber: '', // No phone
            authorityCodeData: _validatedAuthorityCode!,
            verifiedEmail: email,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CitizenVolunteerRegistrationScreen(
            userRole: widget.userRole,
            phoneNumber: '', // No phone
            verifiedEmail: email,
          ),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    await _sendOtp();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) _resendTimer--;
      });
      return _resendTimer > 0;
    });
  }
}
