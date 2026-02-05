import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Settings Screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;

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
          'Settings',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Version
          _buildSettingItem(
            title: 'App Version',
            trailing: const Text(
              '6.1.0',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutralGray,
              ),
            ),
            onTap: null,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 8),
          
          // Volunteer Info
          _buildSettingItem(
            title: 'Volunteer Info',
            onTap: () {
              _showVolunteerInfo();
            },
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),

          // Emergency Numbers
          _buildSettingItem(
            title: 'Emergency Numbers',
            onTap: () {
              _showEmergencyNumbersDialog();
            },
          ).animate().fadeIn(delay: 250.ms),
          
          const SizedBox(height: 8),
          
          // Device Permissions
          _buildSettingItem(
            title: 'Device Permissions',
            onTap: () {
              _showDevicePermissions();
            },
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 8),
          
          // Top Questions
          _buildSettingItem(
            title: 'Top Questions',
            onTap: () {
              Navigator.pushNamed(context, '/top-questions');
            },
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 8),
          
          // Disclaimer
          _buildSettingItem(
            title: 'Disclaimer',
            onTap: () {
              _showDisclaimer();
            },
          ).animate().fadeIn(delay: 500.ms),
          
          const SizedBox(height: 8),
          
          // Privacy Policy
          _buildSettingItem(
            title: 'Privacy Policy',
            onTap: () {
              _showPrivacyPolicy();
            },
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 16),
          
          // Delete Account
          _buildSettingItem(
            title: 'Delete Account',
            titleColor: AppTheme.primaryRed,
            onTap: () {
              _showDeleteAccountDialog();
            },
          ).animate().fadeIn(delay: 700.ms),
          
          const SizedBox(height: 24),
          
          // Dark Mode Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dark mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.neutralGray,
                  ),
                ),
                Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Dark mode enabled' : 'Dark mode disabled',
                        ),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  activeThumbColor: AppTheme.primaryRed,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: titleColor ?? AppTheme.neutralGray,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppTheme.neutralGray)
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showVolunteerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volunteer Info'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Join Sahay as a Volunteer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• Help verify emergency incidents in your area\n'
                '• Provide first aid assistance during emergencies\n'
                '• Support authorities in disaster response\n'
                '• Earn recognition and certificates\n'
                '• Make a difference in your community',
              ),
              SizedBox(height: 12),
              Text(
                'Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Age 18 or above\n'
                '• Valid ID proof\n'
                '• Complete KYC verification\n'
                '• Basic training certification',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDevicePermissions() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Check permissions
    final locationStatus = await Permission.location.status;
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    final notificationStatus = await Permission.notification.status;

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Device Permissions'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   _PermissionItem(
                    icon: Icons.location_on,
                    title: 'Location',
                    description: 'Required for emergency services',
                    status: _getPermissionStatusText(locationStatus),
                    isGranted: locationStatus.isGranted,
                    onRequest: () async {
                      final status = await Permission.location.request();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _PermissionItem(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    description: 'To capture incident photos',
                    status: _getPermissionStatusText(cameraStatus),
                    isGranted: cameraStatus.isGranted,
                    onRequest: () async {
                      final status = await Permission.camera.request();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _PermissionItem(
                    icon: Icons.mic,
                    title: 'Microphone',
                    description: 'For voice SOS alerts',
                    status: _getPermissionStatusText(microphoneStatus),
                    isGranted: microphoneStatus.isGranted,
                    onRequest: () async {
                      final status = await Permission.microphone.request();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _PermissionItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    description: 'Emergency alerts and updates',
                    status: _getPermissionStatusText(notificationStatus),
                    isGranted: notificationStatus.isGranted,
                    onRequest: () async {
                      final status = await Permission.notification.request();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }
      ),
    );
  }

  String _getPermissionStatusText(PermissionStatus status) {
    if (status.isGranted) return 'Granted';
    if (status.isDenied) return 'Denied';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    return 'Restricted';
  }

  void _showDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'Sahay is an emergency response platform designed to assist in crisis situations. '
            'While we strive to provide timely and accurate services:\n\n'
            '• Response times may vary based on location and situation\n'
            '• The platform depends on network connectivity\n'
            '• Users should also contact official emergency services (112)\n'
            '• Information provided is based on user reports and may not be verified\n'
            '• We are not liable for any delays or inaccuracies\n\n'
            'Always prioritize your safety and follow official emergency protocols.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'Last updated: January 12, 2026\n\n'
            '1. Information Collection\n'
            'We collect personal information including name, phone number, location, and emergency contacts.\n\n'
            '2. Data Usage\n'
            'Your data is used solely for emergency response services and improving platform functionality.\n\n'
            '3. Data Sharing\n'
            'Information is shared with emergency services and verified volunteers only during active incidents.\n\n'
            '4. Data Security\n'
            'We use industry-standard encryption to protect your information.\n\n'
            '5. Your Rights\n'
            'You can access, modify, or delete your data at any time through your profile settings.\n\n'
            '6. Contact\n'
            'For privacy concerns, contact us at privacy@sahay.gov.in',
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'This will permanently remove:\n'
          '• Your profile information\n'
          '• Emergency contacts\n'
          '• SOS history\n'
          '• All saved preferences\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }


  Future<void> _showEmergencyNumbersDialog() async {
    final user = ref.read(authControllerProvider);
    final userId = user?.id ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    
    final policeController = TextEditingController(text: prefs.getString('${userId}_sos_police') ?? '112');
    final fireController = TextEditingController(text: prefs.getString('${userId}_sos_fire') ?? '101');
    final ambulanceController = TextEditingController(text: prefs.getString('${userId}_sos_ambulance') ?? '108');
    final womenController = TextEditingController(text: prefs.getString('${userId}_sos_women') ?? '181');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Numbers'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumberField('Police', policeController, Icons.local_police),
              const SizedBox(height: 12),
              _buildNumberField('Fire Brigade', fireController, Icons.local_fire_department),
              const SizedBox(height: 12),
              _buildNumberField('Ambulance', ambulanceController, Icons.medical_services),
              const SizedBox(height: 12),
              _buildNumberField('Women Helpline', womenController, Icons.woman),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await prefs.setString('${userId}_sos_police', policeController.text);
              await prefs.setString('${userId}_sos_fire', fireController.text);
              await prefs.setString('${userId}_sos_ambulance', ambulanceController.text);
              await prefs.setString('${userId}_sos_women', womenController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency numbers saved!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final bool isGranted;
  final VoidCallback? onRequest;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.isGranted,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isGranted ? AppTheme.primaryGreen : AppTheme.neutralGray,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (isGranted)
          const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20)
        else
          TextButton(
            onPressed: onRequest,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
