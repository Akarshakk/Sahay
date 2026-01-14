import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/user_model.dart' as user_model;
import '../../../../core/models/incident_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';
import '../../../incidents/presentation/screens/incident_report_form_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../emergency_contacts/presentation/screens/e_contact_screen.dart';
import '../../../sos_history/presentation/screens/sos_history_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../faq/presentation/screens/top_questions_screen.dart';
import '../../../feed/presentation/screens/community_feed_screen.dart';

/// Modern Material 3 Home Screen with Role-Based UI
/// Citizen: Focus on SOS, Safety Map, Reporting
/// Volunteer: Focus on Tasks, Verification Feed, Resource Toggle
/// Authority: Focus on Heatmaps, Broadcast Alerts
class HomeScreen extends ConsumerStatefulWidget {
  final UserRole userRole;

  const HomeScreen({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Hardcoded location for demo (Mumbai coordinates)
  static const double _demoLatitude = 19.0760;
  static const double _demoLongitude = 72.8777;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: _buildDrawer(user),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildEmergencyBanner(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildServiceGrid(),
                  const SizedBox(height: 24),
                  _buildLocationDisplay(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSOSButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.neutralGray),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sahay',
              style: TextStyle(
                color: AppTheme.neutralGray,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppTheme.neutralGray),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: AppTheme.neutralGray),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildEmergencyBanner() {
    Color accentColor = _getRoleAccentColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed,
            AppTheme.primaryRed.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sahay Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRoleBannerText(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Empty space where logo was - removed "Sahay" text
          const SizedBox(width: 16),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildQuickActions() {
    if (widget.userRole == UserRole.citizen) {
      return _buildCitizenQuickActions();
    } else if (widget.userRole == UserRole.volunteer) {
      return _buildVolunteerQuickActions();
    } else {
      return _buildAuthorityQuickActions();
    }
  }

  Widget _buildCitizenQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.person_outline,
              label: 'Profile',
              color: AppTheme.citizenAccent,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.history,
              label: 'SOS History',
              color: AppTheme.primaryOrange,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.public,
              label: 'Community',
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityFeedScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.help_outline,
              label: 'Help',
              color: AppTheme.neutralGray,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.task_alt,
              label: 'My Tasks',
              color: AppTheme.volunteerAccent,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.verified_outlined,
              label: 'Verify',
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityFeedScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.inventory_outlined,
              label: 'Resources',
              color: AppTheme.primaryGreen,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.map_outlined,
              label: 'Heatmap',
              color: AppTheme.authorityAccent,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.campaign_outlined,
              label: 'Broadcast',
              color: AppTheme.primaryOrange,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              color: AppTheme.primaryGreen,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.neutralGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildServiceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Emergency Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildServiceCard(
                icon: Icons.local_police,
                label: 'POLICE',
                color: const Color(0xFF1565C0),
                type: IncidentType.police,
              ),
              _buildServiceCard(
                icon: Icons.local_fire_department,
                label: 'FIRE',
                color: const Color(0xFFD32F2F),
                type: IncidentType.fire,
              ),
              _buildServiceCard(
                icon: Icons.medical_services,
                label: 'MEDICAL',
                color: const Color(0xFFE53935),
                type: IncidentType.medical,
              ),
              _buildServiceCard(
                icon: Icons.warning,
                label: 'DISASTER',
                color: const Color(0xFFFF6F00),
                type: IncidentType.disaster,
              ),
              _buildServiceCard(
                icon: Icons.woman,
                label: 'WOMAN',
                color: const Color(0xFF8E24AA),
                type: IncidentType.woman,
              ),
              _buildServiceCard(
                icon: Icons.child_care,
                label: 'CHILD',
                color: const Color(0xFF00897B),
                type: IncidentType.child,
              ),
              _buildServiceCard(
                icon: Icons.elderly,
                label: 'ELDERLY',
                color: const Color(0xFF6D4C41),
                type: IncidentType.elderly,
              ),
              _buildServiceCard(
                icon: Icons.train,
                label: 'RAILWAY',
                color: const Color(0xFF5E35B1),
                type: IncidentType.railway,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required Color color,
    required IncidentType type,
  }) {
    return GestureDetector(
      onTap: () {
        _showIncidentReportDialog(type);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.neutralGray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: (label.hashCode % 400).ms);
  }

  Widget _buildLocationDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Detecting location...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _triggerEmergencySOS();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
  }

  Color _getRoleAccentColor() {
    switch (widget.userRole) {
      case UserRole.citizen:
        return AppTheme.citizenAccent;
      case UserRole.volunteer:
        return AppTheme.volunteerAccent;
      case UserRole.authority:
        return AppTheme.authorityAccent;
    }
  }

  String _getRoleBannerText() {
    switch (widget.userRole) {
      case UserRole.citizen:
        return '• One App for All Emergency Needs\n• Request Volunteer Assistance Anytime\n• Get Live Updates on Your Request Status\n• Share Your Location for Faster Help';
      case UserRole.volunteer:
        return '• Help Your Community in Crisis\n• Verify Local Incidents\n• Manage Resource Availability\n• Respond to Nearby Emergencies';
      case UserRole.authority:
        return '• Monitor Live Incident Heatmaps\n• Broadcast Critical Alerts\n• Coordinate Emergency Response\n• Analyze Crisis Patterns';
    }
  }

  void _showIncidentReportDialog(IncidentType type) {
    // Navigate to Incident Report Form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentReportScreen(incidentType: type),
      ),
    );
  }

  /// Trigger Emergency SOS with Deduplication Check
  Future<void> _triggerEmergencySOS() async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking for nearby incidents...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Check for duplicates using hardcoded location
      final duplicateCheck = await ref
          .read(incidentControllerProvider.notifier)
          .checkDuplicate(_demoLatitude, _demoLongitude);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (duplicateCheck.isSuccess && duplicateCheck.data != null) {
        // Found duplicate - show alert
        _showDuplicateAlert(duplicateCheck.data!);
      } else {
        // No duplicate - proceed to submit
        await _submitEmergencySOS();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showError('Failed to check for duplicates: $e');
    }
  }

  /// Submit Emergency SOS
  Future<void> _submitEmergencySOS() async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final now = DateTime.now();
    final incident = IncidentModel(
      id: 'sos-${now.millisecondsSinceEpoch}',
      title: 'Emergency SOS',
      description: 'Emergency assistance required - triggered via SOS button',
      type: IncidentType.police,
      severity: SeverityLevel.critical,
      latitude: _demoLatitude,
      longitude: _demoLongitude,
      reportedBy: user.phone,
      reportedAt: now,
      timestamp: now,
      status: IncidentStatus.pending,
      isSynced: false,
      mediaUrls: const [],
      verificationCount: 0,
    );

    final result = await ref
        .read(incidentControllerProvider.notifier)
        .submitReport(incident: incident);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency SOS sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📡 No connection - SOS queued for sync'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(result.error ?? 'Failed to send SOS');
    }
  }

  /// Show duplicate incident alert
  void _showDuplicateAlert(IncidentModel duplicate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 48, color: Colors.orange),
        title: const Text('Similar Incident Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A similar ${duplicate.type.name.toUpperCase()} incident was reported nearby:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('📍 Location: ${duplicate.latitude}, ${duplicate.longitude}'),
            Text('🕐 Time: ${_formatTime(duplicate.reportedAt)}'),
            Text('⚠️ Severity: ${duplicate.severity.name}'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to submit anyway or cancel?',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _submitEmergencySOS();
            },
            child: const Text('Submit Anyway'),
          ),
        ],
      ),
    );
  }

  /// Format time ago
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build Navigation Drawer
  Widget _buildDrawer(user_model.User? user) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User Name
                  Text(
                    user?.name ?? 'Akarshak Singh',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone Number
                  Text(
                    '+91 ${user?.phone ?? '8605720924'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutralGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.contact_emergency,
              title: 'E-Contact',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EContactScreen()),
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.history,
              title: 'SOS History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SOSHistoryScreen()),
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.info,
              title: 'App Info',
              onTap: () {
                Navigator.pop(context);
                _showAppInfo();
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.question_answer,
              title: 'Top Questions',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopQuestionsScreen()),
                );
              },
            ),
            
            const Divider(height: 32),
            
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Version Info
            Center(
              child: Text(
                'Version 6.1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  /// Build Drawer Menu Item
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryRed : AppTheme.primaryRed.withOpacity(0.7),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.neutralGray,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryRed.withOpacity(0.05),
      onTap: onTap,
    );
  }
  
  /// Show App Info Dialog
  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Sahay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sahay - Crisis Response Platform',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Version: 6.1.0'),
            const SizedBox(height: 8),
            Text(
              'A next-generation crisis response platform based on India\'s 112 emergency service.',
              style: TextStyle(color: AppTheme.neutralGray.withOpacity(0.7)),
            ),
          ],
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
  
  /// Handle Logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Clear auth state
              ref.read(authControllerProvider.notifier).logout();
              // Navigate to login screen
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Placeholder for Incident Report Screen
class IncidentReportScreen extends StatelessWidget {
  final IncidentType incidentType;

  const IncidentReportScreen({super.key, required this.incidentType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report ${incidentType.name.toUpperCase()}')),
      body: const Center(child: Text('Incident Report Form')),
    );
  }
}
