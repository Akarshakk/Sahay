import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'sos_active_screen.dart';

/// Emergency type for SOS - determines which number to call
enum EmergencyType {
  police('112', 'Police'),
  fire('101', 'Fire Brigade'),
  medical('102', 'Medical'),
  disaster('1077', 'Disaster'),
  women('1091', 'Women Helpline'),
  child('1098', 'Child Helpline'),
  elderly('1253', 'Elderly Helpline'),
  railway('131', 'Railway');

  final String number;
  final String label;
  const EmergencyType(this.number, this.label);
}

/// SOS Countdown Screen - Shows 5 second countdown before triggering SOS
class SOSCountdownScreen extends ConsumerStatefulWidget {
  final bool requireVolunteerAssistance;
  final bool silentMode;
  final EmergencyType emergencyType;
  
  const SOSCountdownScreen({
    super.key,
    this.requireVolunteerAssistance = true,
    this.silentMode = false,
    this.emergencyType = EmergencyType.police,
  });

  @override
  ConsumerState<SOSCountdownScreen> createState() => _SOSCountdownScreenState();
}

class _SOSCountdownScreenState extends ConsumerState<SOSCountdownScreen> 
    with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  bool _sendSMSToContacts = false;
  bool _requireVolunteerAssistance = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _requireVolunteerAssistance = widget.requireVolunteerAssistance;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        // Haptic feedback on each tick
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _triggerSOS() {
    // If SMS to contacts is enabled, open SMS app first
    if (_sendSMSToContacts) {
      _openSMSWithEmergencyMessage();
    }
    
    // Navigate to active SOS screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SOSActiveScreen(
          silentMode: false,
          requireVolunteerAssistance: _requireVolunteerAssistance,
          emergencyNumber: widget.emergencyType.number,
          emergencyLabel: widget.emergencyType.label,
        ),
      ),
    );
  }
  
  Future<void> _openSMSWithEmergencyMessage() async {
    final user = ref.read(authControllerProvider);
    final emergencyContacts = user?.emergencyContacts ?? [];
    
    if (emergencyContacts.isEmpty) {
      return;
    }
    
    // Get all phone numbers
    final phoneNumbers = emergencyContacts.map((c) => c.phone).join(',');
    
    // Create emergency message
    final message = 'EMERGENCY SOS! I need help. This is an emergency alert from ${user?.name ?? "me"} via Sahay app. Please call me or contact emergency services. Emergency type: ${widget.emergencyType.label}.';
    
    // Create SMS URI
    final smsUri = Uri(
      scheme: 'sms',
      path: phoneNumbers,
      queryParameters: {'body': message},
    );
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('Failed to open SMS: $e');
    }
  }

  void _immediateTrigger() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    _triggerSOS();
  }

  void _cancelSOS() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: _cancelSOS,
        ),
        title: const Text(
          'Sahay',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sending',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Emergency Alert',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'When the timer reaches zero, an SOS will be sent.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Countdown Circle Button
                  GestureDetector(
                    onTap: _immediateTrigger,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 200 + (_pulseController.value * 10),
                          height: 200 + (_pulseController.value * 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryRed,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRed.withOpacity(0.3),
                                blurRadius: 20 + (_pulseController.value * 10),
                                spreadRadius: 5 + (_pulseController.value * 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$_countdown',
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate()
                    .scale(duration: 300.ms, curve: Curves.easeOut),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Tap the timer to send an immediate SOS alert',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Bottom Options
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Send SMS to E-Contacts Option
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CheckboxListTile(
                      value: _sendSMSToContacts,
                      onChanged: (value) {
                        setState(() => _sendSMSToContacts = value ?? false);
                      },
                      title: Row(
                        children: [
                          const Icon(Icons.sms, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              'Send SMS to E-Contacts',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppTheme.primaryRed,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Volunteer Assistance Option
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CheckboxListTile(
                      value: _requireVolunteerAssistance,
                      onChanged: (value) {
                        setState(() => _requireVolunteerAssistance = value ?? true);
                      },
                      title: Row(
                        children: [
                          const Icon(Icons.people, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              'Require volunteer Assistance',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppTheme.primaryRed,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _cancelSOS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
}
