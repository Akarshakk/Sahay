import 'package:flutter/material.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import 'citizen_volunteer_registration_screen.dart';

/// OTP Verification Screen for Mobile Number
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
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  int _resendTimer = 30;

  // Web-specific confirmation result
  ConfirmationResult? _webConfirmationResult;
  // Mobile-specific verification ID
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Title
                Text(
                  _otpSent ? 'Verify OTP' : 'Enter Mobile Number',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  _otpSent
                      ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                      : 'We\'ll send you a verification code',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray.withOpacity(0.7),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                if (!_otpSent) ...[
                  // Phone Number Input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    enabled: !_isLoading,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon:
                          const Icon(Icons.phone, color: AppTheme.primaryRed),
                      prefixText: '+91 ',
                      prefixStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.neutralGray.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryRed, width: 2),
                      ),
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
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
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
                                  color: AppTheme.neutralGray.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryRed, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
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
                              ? AppTheme.neutralGray.withOpacity(0.5)
                              : AppTheme.primaryRed,
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
                      backgroundColor: AppTheme.primaryRed,
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
                            _otpSent ? 'VERIFY & CONTINUE' : 'SEND OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = '+91${_phoneController.text}';

    try {
      if (kIsWeb) {
        // Web-specific implementation - Firebase handles reCAPTCHA automatically
        final confirmationResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);

        if (!mounted) return;
        setState(() {
          _webConfirmationResult = confirmationResult;
          _isLoading = false;
          _otpSent = true;
          _resendTimer = 30;
        });
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        // Android/iOS implementation
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Android only: Auto-resolution
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            _navigateToNextScreen();
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed ($phoneNumber): ${e.message}'),
                backgroundColor: AppTheme.primaryRed,
                duration: const Duration(seconds: 5),
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
              _otpSent = true;
              _resendTimer = 30;
            });
            _startResendTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully!'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
              });
            }
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Verification Failed';
      if (e.code == 'web-context-cancelled') {
        errorMessage = 'Verification cancelled by user';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Try again later.';
      } else if (e.code == 'invalid-phone-number') {
        errorMessage = 'Invalid phone number format';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed ($phoneNumber): $errorMessage'),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete OTP'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    // Validation for Mobile
    if (!kIsWeb && _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Verification ID missing. Please resend OTP.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    // Validation for Web
    if (kIsWeb && _webConfirmationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error: Confirmation Result missing. Please resend OTP.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // Web verification
        await _webConfirmationResult!.confirm(otp);
      } else {
        // Mobile verification
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _navigateToNextScreen();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Invalid OTP'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CitizenVolunteerRegistrationScreen(
          userRole: widget.userRole,
          phoneNumber: _phoneController.text,
        ),
      ),
    );
  }

  Future<void> _resendOtp() async {
    await _sendOtp();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        }
      });

      return _resendTimer > 0;
    });
  }
}
