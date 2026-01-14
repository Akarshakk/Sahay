import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// FAQ Item Model
class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

/// Top Questions Screen
class TopQuestionsScreen extends ConsumerStatefulWidget {
  const TopQuestionsScreen({super.key});

  @override
  ConsumerState<TopQuestionsScreen> createState() => _TopQuestionsScreenState();
}

class _TopQuestionsScreenState extends ConsumerState<TopQuestionsScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How to Register?',
      answer: '1. Install the app.\n'
          '2. Accept the terms and give permissions.\n'
          '3. Select your state and enter your mobile number.\n'
          '4. Tap "Generate OTP."\n'
          '5. Enter the OTP sent to your phone.\n'
          '6. Allow location access.\n'
          '7. Enter your name, date of birth, and gender to register.\n'
          '8. Choose to volunteer (optional).\n'
          '9. Tap "Submit."',
      isExpanded: true,
    ),
    FAQItem(
      question: 'How to Add Emergency Contacts?',
      answer: '1. Open the app and go to "E-Contact" from the menu.\n'
          '2. Tap on "Add Contact" slot.\n'
          '3. Enter contact name, phone number, and relation.\n'
          '4. Tap "Save" to add the contact.\n'
          '5. Repeat to add up to 5 emergency contacts.\n'
          '6. These contacts will be notified when you raise an SOS.',
    ),
    FAQItem(
      question: 'How to complete KYC verification as a volunteer?',
      answer: '1. Go to Settings > Volunteer Info.\n'
          '2. Tap on "Complete KYC Verification."\n'
          '3. Upload a photo of your Aadhaar card or government ID.\n'
          '4. Take a selfie for facial verification.\n'
          '5. Enter your Aadhaar number or ID details.\n'
          '6. Submit the form and wait for verification (24-48 hours).\n'
          '7. You\'ll receive a notification once verified.',
    ),
    FAQItem(
      question: 'How to provide Volunteering Service as a Verified Volunteer?',
      answer: '1. Complete KYC verification first.\n'
          '2. Enable "Available for Service" toggle in your profile.\n'
          '3. You\'ll receive nearby emergency alerts.\n'
          '4. Tap on alert to view incident details.\n'
          '5. If you can help, tap "Accept Task."\n'
          '6. Navigate to location using the map.\n'
          '7. Provide assistance and update incident status.\n'
          '8. Mark task as complete when done.',
    ),
    FAQItem(
      question: 'How to Raise an Emergency SOS?',
      answer: '1. Open the Sahay app.\n'
          '2. Tap the red "SOS" button on the home screen.\n'
          '3. Select emergency type (Medical, Fire, Crime, etc.).\n'
          '4. Your location will be automatically shared.\n'
          '5. Add voice note or photos if possible (optional).\n'
          '6. Tap "Send SOS."\n'
          '7. Emergency services and nearby volunteers will be alerted.\n'
          '8. Your emergency contacts will also be notified.',
    ),
    FAQItem(
      question: 'How to update my profile details?',
      answer: '1. Open the menu and tap "Profile."\n'
          '2. Tap the edit icon (pencil) at the top right.\n'
          '3. Update your name, profession, or address.\n'
          '4. Tap on your profile picture to change it.\n'
          '5. Tap "Save Changes" when done.\n'
          '6. Your profile will be updated immediately.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Top Questions',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryRed),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.translate, color: AppTheme.primaryRed),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language selection not implemented in demo'),
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Button
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'FAQ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn().scale(),
          
          const SizedBox(height: 24),
          
          // FAQ List
          ...List.generate(_faqs.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFAQItem(_faqs[index], index),
            ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: -0.2, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neutralGray.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralGray,
            ),
          ),
          trailing: Icon(
            faq.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppTheme.primaryRed,
          ),
          initiallyExpanded: faq.isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              faq.isExpanded = expanded;
            });
          },
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralGray.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
