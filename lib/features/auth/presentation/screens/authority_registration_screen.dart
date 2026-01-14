import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/authority_dashboard_screen.dart';

/// Authority Registration Screen
class AuthorityRegistrationScreen extends ConsumerStatefulWidget {
  const AuthorityRegistrationScreen({super.key});

  @override
  ConsumerState<AuthorityRegistrationScreen> createState() =>
      _AuthorityRegistrationScreenState();
}

class _AuthorityRegistrationScreenState
    extends ConsumerState<AuthorityRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNumberController = TextEditingController();
  final _otherDeptController = TextEditingController();
  
  String? _selectedDepartment;
  bool _isLoading = false;

  final List<String> _departments = [
    'Police',
    'Hospital (Private)',
    'Hospital (Government)',
    'Fire Department',
    'Railways',
    'Other',
  ];

  @override
  void dispose() {
    _regNumberController.dispose();
    _otherDeptController.dispose();
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
                const SizedBox(height: 20),
                
                // Authority Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.authorityAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.authorityAccent,
                      ),
                    ),
                    child: const Text(
                      'AUTHORITY',
                      style: TextStyle(
                        color: AppTheme.authorityAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(),
                
                const SizedBox(height: 32),
                
                // Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.authorityAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.authorityAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.authorityAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please provide your government registration details for verification',
                          style: TextStyle(
                            color: AppTheme.neutralGray.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
                
                const SizedBox(height: 32),
                
                // Government Registration Number
                TextFormField(
                  controller: _regNumberController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Government Registration Number *',
                    hintText: 'Enter your registration number',
                    prefixIcon: const Icon(Icons.badge, color: AppTheme.authorityAccent),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.neutralGray.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.authorityAccent, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your registration number';
                    }
                    if (value.length < 5) {
                      return 'Registration number must be at least 5 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 20),
                
                // Department Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Department *',
                    hintText: 'Select your department',
                    prefixIcon: const Icon(Icons.business, color: AppTheme.authorityAccent),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.neutralGray.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.authorityAccent, width: 2),
                    ),
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your department';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 20),
                
                // Other Department Input (Conditional)
                if (_selectedDepartment == 'Other') ...[
                  TextFormField(
                    controller: _otherDeptController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Specify Department *',
                      hintText: 'Enter your department name',
                      prefixIcon: const Icon(Icons.edit, color: AppTheme.authorityAccent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.neutralGray.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.authorityAccent, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (_selectedDepartment == 'Other' &&
                          (value == null || value.isEmpty)) {
                        return 'Please specify your department';
                      }
                      return null;
                    },
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 20),
                ],
                
                const SizedBox(height: 12),
                
                // Submit Button
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
                ).animate().fadeIn(delay: 400.ms).scale(),
                
                const SizedBox(height: 24),
                
                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber[800],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your registration will be verified by our team. You will receive a confirmation within 24-48 hours.',
                          style: TextStyle(
                            color: AppTheme.neutralGray.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate registration API call
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authority registration submitted successfully!\nYou will be notified once verified.'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 4),
      ),
    );
    
    // Navigate to authority dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthorityDashboardScreen(),
      ),
      (route) => false,
    );
  }
}
