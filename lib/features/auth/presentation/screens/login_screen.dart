import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart' as user_model;
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/ashoka_chakra.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/authority_dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref.read(authControllerProvider.notifier).login(_phoneController.text);

      if (!mounted) return;
      
      if (user != null) {
        // Convert user.role (from user_model) to UserRole (from app_enums)
        UserRole role;
        switch (user.role) {
          case user_model.UserRole.citizen:
            role = UserRole.citizen;
            break;
          case user_model.UserRole.volunteer:
            role = UserRole.volunteer;
            break;
          case user_model.UserRole.authority:
            role = UserRole.authority;
            break;
        }
        
        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.name}! (${role.name.toUpperCase()})'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to Home Screen for ALL roles
        // This ensures everyone gets the standard drawer menu and layout
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(userRole: role),
          ),
        );
      } else {
        throw Exception('Login failed - no user data returned');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Ashoka Chakra
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF9933),
                          Color(0xFFFFFFFF),
                          Color(0xFF138808),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: AshokaChakra(
                        size: 55,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Sahay',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Log in to the Sahay App',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 48),
                  
                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mobile Number Field
                        const Text(
                          'Mobile Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Enter 10-digit mobile number',
                            prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                            filled: true,
                            fillColor: AppTheme.backgroundLight,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Generate OTP Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Test Credentials Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Test Credentials:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildTestCredential('1111111111', 'Citizen'),
                              _buildTestCredential('2222222222', 'Volunteer'),
                              _buildTestCredential('3333333333', 'Authority'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Register Link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  
                  const SizedBox(height: 8),
                  
                  // Terms
                  Text(
                    'By continuing, you agree to the Sahay app\nterms and conditions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'version: 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCredential(String phone, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            phone,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '→ $role',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
