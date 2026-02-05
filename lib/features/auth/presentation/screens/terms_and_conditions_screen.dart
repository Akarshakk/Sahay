import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Terms and Conditions Screen for Sahay Crisis Response Platform
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9933), Color(0xFF138808)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sahay Terms of Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last updated: February 2026',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 24),

            // Terms Content
            _buildSection(
              number: '1',
              title: 'Acceptance of Terms',
              content: '''By accessing and using the Sahay Crisis Response Platform ("the App"), you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.

Sahay is designed to assist citizens, volunteers, and authorities during emergency situations. Your use of this platform is subject to your compliance with all applicable laws and regulations.''',
            ).animate().fadeIn(delay: 100.ms),

            _buildSection(
              number: '2',
              title: 'Service Description',
              content: '''Sahay is a crisis response coordination platform that provides:
• One-tap SOS emergency alerts with location sharing
• Community incident reporting and monitoring
• Task coordination for volunteers
• Real-time emergency monitoring for authorities
• Communication between citizens, volunteers, and emergency responders

The App supplements but does NOT replace official emergency services. In case of immediate danger, always contact official emergency numbers: 100 (Police), 101 (Fire), 102 (Ambulance), 108 (Disaster Response), or 112 (National Emergency).''',
            ).animate().fadeIn(delay: 200.ms),

            _buildSection(
              number: '3',
              title: 'User Responsibilities',
              content: '''As a user of Sahay, you agree to:
• Provide accurate and truthful information during registration
• Use the SOS feature only for genuine emergencies
• Report incidents honestly and accurately
• Not submit false, misleading, or malicious reports
• Keep your account credentials secure and confidential
• Notify us immediately of any unauthorized account access
• Comply with all applicable local, state, and national laws

False emergency reports may result in immediate account termination and may be reported to law enforcement authorities.''',
            ).animate().fadeIn(delay: 300.ms),

            _buildSection(
              number: '4',
              title: 'Location Services & Data',
              content: '''Sahay requires access to your device's location services to function effectively. By using the App, you consent to:
• Collection of your real-time GPS location during emergencies
• Sharing of your location with emergency responders and volunteers
• Use of location data to display nearby incidents
• Storage of location history for emergency coordination

Location data is essential for emergency response. You may disable location services, but this will limit the App's ability to assist you during emergencies.''',
            ).animate().fadeIn(delay: 400.ms),

            _buildSection(
              number: '5',
              title: 'Privacy & Data Protection',
              content: '''We take your privacy seriously. By using Sahay, you acknowledge:
• Your personal information (name, phone, email, address) is collected for emergency response purposes
• Your data is stored securely using industry-standard encryption
• We may share your information with emergency responders during crisis situations
• Your data will not be sold to third parties for marketing
• You can request deletion of your account and associated data
• We comply with applicable data protection regulations

For complete details, please review our Privacy Policy.''',
            ).animate().fadeIn(delay: 500.ms),

            _buildSection(
              number: '6',
              title: 'Role-Specific Terms',
              content: '''CITIZENS:
• Report emergencies truthfully and accurately
• Provide helpful information to aid responders
• Do not abuse the SOS system

VOLUNTEERS:
• Complete assigned tasks to the best of your ability
• Maintain professional conduct during emergency response
• Follow instructions from authorities
• Report your availability status accurately
• Undergo verification as required

AUTHORITIES:
• Use the platform for official emergency management only
• Handle citizen data with confidentiality
• Coordinate responses in accordance with official protocols''',
            ).animate().fadeIn(delay: 600.ms),

            _buildSection(
              number: '7',
              title: 'Limitation of Liability',
              content: '''Sahay is provided "as is" without warranties of any kind. We do not guarantee:
• Continuous, uninterrupted service availability
• Immediate response from authorities or volunteers
• Accuracy of user-submitted incident reports
• Specific response times for emergencies

The Sahay team and associated parties shall not be liable for:
• Any damages arising from the use or inability to use the App
• Delays in emergency response
• Actions or inactions of volunteers or authorities
• Technical failures or service interruptions
• Loss of data or unauthorized access

This platform is a coordination tool and does not replace professional emergency services.''',
            ).animate().fadeIn(delay: 700.ms),

            _buildSection(
              number: '8',
              title: 'Account Termination',
              content: '''We reserve the right to suspend or terminate your account if you:
• Submit false emergency reports
• Violate these Terms and Conditions
• Engage in harassment or abusive behavior
• Misuse the platform in any way
• Fail to comply with applicable laws

You may delete your account at any time through the App settings.''',
            ).animate().fadeIn(delay: 800.ms),

            _buildSection(
              number: '9',
              title: 'Changes to Terms',
              content: '''We may update these Terms and Conditions from time to time. Significant changes will be notified through the App. Your continued use of Sahay after changes are posted constitutes acceptance of the modified terms.

We encourage you to review these terms periodically.''',
            ).animate().fadeIn(delay: 900.ms),

            _buildSection(
              number: '10',
              title: 'Contact Information',
              content: '''For questions, concerns, or feedback regarding these Terms and Conditions or the Sahay platform, please contact us at:

Email: support@sahay.app
Website: www.sahay.app

By using Sahay, you acknowledge that you have read, understood, and agree to these Terms and Conditions.''',
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 32),

            // Emergency Numbers Reminder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency, color: AppTheme.primaryRed, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Numbers (India)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyNumber('Police', '100'),
                  _buildEmergencyNumber('Fire', '101'),
                  _buildEmergencyNumber('Ambulance', '102'),
                  _buildEmergencyNumber('Disaster Response', '108'),
                  _buildEmergencyNumber('National Emergency', '112'),
                ],
              ),
            ).animate().fadeIn(delay: 1100.ms).scale(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.neutralGray.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumber(String service, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutralGray,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
