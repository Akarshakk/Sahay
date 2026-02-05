import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/hardware_trigger_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/user_model.dart' as user_model;
import '../../../../core/models/incident_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../incidents/presentation/screens/incident_report_form_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../emergency_contacts/presentation/screens/e_contact_screen.dart';
import '../../../sos_history/presentation/screens/sos_history_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../faq/presentation/screens/top_questions_screen.dart';
import '../../../feed/presentation/screens/community_feed_screen.dart';
import '../../../volunteer/presentation/screens/volunteer_dashboard_screen.dart';
import '../../../volunteer/presentation/screens/volunteer_tasks_detailed_screen.dart';
import '../../../volunteer/presentation/screens/resources_screen.dart';
import '../../../authority/presentation/screens/heatmap_screen.dart';
import '../../../authority/presentation/screens/analytics_screen.dart';
import '../../../authority/presentation/screens/broadcast_screen.dart';
import 'authority_dashboard_screen.dart';

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
  // Default location for fallback (Mumbai coordinates)
  static const double _defaultLatitude = 19.0760;
  static const double _defaultLongitude = 72.8777;
  
  List<Map<String, dynamic>> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Hardware Trigger Listener
    HardwareTriggerService().onEmergencyTriggered = _submitEmergencySOS;
    HardwareTriggerService().initialize();
    
    // Initialize WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWebSocket();
    });
  }

  void _initWebSocket() {
    final user = ref.read(authControllerProvider);
    final ws = ref.read(webSocketServiceProvider);
    
    // Connect
    if (user != null && !ws.isConnected) {
      ws.connect(user.id);
    }

    // Join Region
    if (user != null) {
      if (user.registeredArea != null && user.registeredArea!.isNotEmpty) {
        ws.joinRegion(user.registeredArea!);
        _fetchMissedBroadcasts(user.registeredArea!);
      } else if (user.state != null && user.state!.isNotEmpty) {
        ws.joinRegion(user.state!);
        _fetchMissedBroadcasts(user.state!);
      }
    }

    // Listen for Broadcasts
    ws.onEmergencyBroadcast((data) {
      if (!mounted) return;
      _saveNotification(data['data']);
      _showBroadcastDialog(data['data']);
    });
  }
  
  void _showBroadcastDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('EMERGENCY ALERT', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Alert', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(data['message'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Region: ${data['region']}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            Text('Priority: ${data['priority']}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('I UNDERSTAND'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    HardwareTriggerService().dispose();
    super.dispose();
  }
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
          onPressed: () => _showNotificationsPanel(),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: AppTheme.neutralGray),
          onPressed: () => _showAppInfo(),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.history,
              label: 'SOS History',
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SOSHistoryScreen()),
                );
              },
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopQuestionsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Dashboard Button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VolunteerDashboardScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.volunteerAccent, AppTheme.volunteerAccent.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.volunteerAccent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View stats, levels & achievements',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.task_alt,
                  label: 'My Tasks',
                  color: AppTheme.volunteerAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VolunteerTasksDetailedScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.verified_outlined,
                  label: 'Verify',
                  color: AppTheme.primaryOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityFeedScreen(canVerify: true)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.inventory_outlined,
                  label: 'Resources',
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResourcesScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityQuickActions() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        // Authority Dashboard Button (Command Center)
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthorityDashboardScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.authorityAccent, AppTheme.authorityAccent.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.authorityAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage incidents, alerts & analytics',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        
        // Verify and Resources (New Row)
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.verified_outlined,
                label: 'Verify',
                color: AppTheme.primaryOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityFeedScreen(canVerify: true)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.inventory_outlined,
                label: 'Resources',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResourcesScreen()),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        // Core Authority Tools
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.map_outlined,
                label: 'Heatmap',
                color: AppTheme.authorityAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HeatmapScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.campaign_outlined,
                label: 'Broadcast',
                color: AppTheme.primaryOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BroadcastScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                ),
              ),
            ),
          ],
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
              style: const TextStyle(
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
              style: const TextStyle(
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
    final locationAsync = ref.watch(currentLocationProvider);
    
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
          const Icon(Icons.location_on, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                locationAsync.when(
                  data: (location) => Text(
                    location?.address ?? 'Location unavailable',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  loading: () => const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Detecting location...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => const Text(
                    'Enable location permission',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: () {
              ref.invalidate(currentLocationProvider);
            },
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
    // Navigate to full Incident Report Form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentReportFormScreen(incidentType: type),
      ),
    );
  }

  /// Trigger Emergency SOS - Shows emergency call/SMS options
 // Trigger Emergency SOS - Shows emergency call/SMS options
Future<void> _triggerEmergencySOS() async {
  // Get current location
  final locationData = ref.read(currentLocationProvider).valueOrNull;
  final locationText = locationData != null 
      ? '📍 ${locationData.address}\n(${locationData.latitude.toStringAsFixed(4)}, ${locationData.longitude.toStringAsFixed(4)})'
      : '📍 Location unavailable';

  // Load custom numbers
  final user = ref.read(authControllerProvider);
  final userId = user?.id ?? 'guest';
  final prefs = await SharedPreferences.getInstance();
  final policeNum = prefs.getString('${userId}_sos_police') ?? '112';
  final fireNum = prefs.getString('${userId}_sos_fire') ?? '101';
  final ambulanceNum = prefs.getString('${userId}_sos_ambulance') ?? '108';
  final womenNum = prefs.getString('${userId}_sos_women') ?? '181';

  if (!mounted) return;

  // Show Emergency Dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationText,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          
          // Trigger Alert Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _submitEmergencySOS();
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('TRIGGER SOS ALERT (LOG HISTORY)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Select emergency service to call:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Emergency Call Buttons
          _buildEmergencyCallButton(
            icon: Icons.local_police,
            label: 'Police ($policeNum)',
            number: policeNum,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 8),
          _buildEmergencyCallButton(
            icon: Icons.local_fire_department,
            label: 'Fire Brigade ($fireNum)',
            number: fireNum,
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(height: 8),
          _buildEmergencyCallButton(
            icon: Icons.medical_services,
            label: 'Ambulance ($ambulanceNum)',
            number: ambulanceNum,
            color: const Color(0xFFE53935),
          ),
          const SizedBox(height: 8),
          _buildEmergencyCallButton(
            icon: Icons.woman,
            label: 'Women Helpline ($womenNum)',
            number: womenNum,
            color: const Color(0xFF8E24AA),
          ),
          const SizedBox(height: 16),
          // SMS Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sendEmergencySMS(locationData),
              icon: const Icon(Icons.sms),
              label: const Text('Send SMS to Emergency Contacts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

  /// Build emergency call button
  Widget _buildEmergencyCallButton({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _makeEmergencyCall(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text(number, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.call, size: 20),
          ],
        ),
      ),
    );
  }

  /// Make emergency phone call
  Future<void> _makeEmergencyCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showError('Cannot make phone calls on this device');
      }
    } catch (e) {
      _showError('Failed to initiate call: $e');
    }
  }

  /// Send emergency SMS with location
  Future<void> _sendEmergencySMS(LocationData? location) async {
    final String message = location != null
        ? 'EMERGENCY SOS! I need help. My location: ${location.address} (${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})'
        : 'EMERGENCY SOS! I need help. Please contact me immediately.';
    
    // Default emergency contacts (Police control room)
    const String emergencyNumber = '112';
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyNumber,
      queryParameters: {'body': message},
    );
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showError('Cannot send SMS on this device');
      }
    } catch (e) {
      _showError('Failed to send SMS: $e');
    }
  }

  /// Submit Emergency SOS
  Future<void> _submitEmergencySOS() async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final location = ref.read(currentLocationProvider).valueOrNull;

    try {
      final api = ref.read(apiServiceProvider);
      
      // 1. Trigger SOS API
      await api.triggerSOS(
        latitude: location?.latitude ?? _defaultLatitude,
        longitude: location?.longitude ?? _defaultLongitude,
        type: 'POLICE', // Default
        address: location?.address,
      );

      // 2. Show success
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency SOS Triggered! Creating logs...'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 3. Send SMS automatically (optional, keeps existing logic)
      // _sendEmergencySMS(location); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to trigger SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              decoration: const BoxDecoration(
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
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone Number
                  Text(
                    '+91 ${user?.phone ?? 'Not logged in'}',
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
            
            // Authority Specific Menu Item
            if (user?.role == UserRole.authority)
              _buildDrawerItem(
                icon: Icons.shield,
                title: 'Command Center',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthorityDashboardScreen()),
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

  /// Show Notifications Panel
  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              if (_notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No new notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._notifications.map((n) => _buildNotificationItem(
                  icon: Icons.warning_amber,
                  title: n['title'] ?? 'Alert',
                  subtitle: n['message'] ?? '',
                  time: _formatTime(DateTime.tryParse(n['time'] ?? '') ?? DateTime.now()),
                  color: (n['priority'] == 'High' || n['priority'] == 'Critical') 
                      ? AppTheme.primaryRed 
                      : AppTheme.primaryOrange,
                )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchMissedBroadcasts(String region) async {
    try {
      final broadcasts = await ref.read(apiServiceProvider).getBroadcasts(region);
      bool shownDialog = false; // Only show one dialog to avoid stacking

      // Sort by newest first
      if (broadcasts.isNotEmpty) {
        broadcasts.sort((a, b) {
          DateTime? timeA;
          DateTime? timeB;
          
          // Handle Firestore Timestamp format
          if (a['createdAt'] is Map) {
            final int? secondsA = a['createdAt']['_seconds'];
            if (secondsA != null) {
              timeA = DateTime.fromMillisecondsSinceEpoch(secondsA * 1000);
            }
          } else if (a['createdAt'] is String) {
            timeA = DateTime.tryParse(a['createdAt']);
          }
          
          if (b['createdAt'] is Map) {
            final int? secondsB = b['createdAt']['_seconds'];
            if (secondsB != null) {
              timeB = DateTime.fromMillisecondsSinceEpoch(secondsB * 1000);
            }
          } else if (b['createdAt'] is String) {
            timeB = DateTime.tryParse(b['createdAt']);
          }
          
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });
      }

      print('DEBUG: Fetched ${broadcasts.length} broadcasts for region $region');
      
      for (var b in broadcasts) {
        // Check if already saved
        final prefs = await SharedPreferences.getInstance();
        final List<String> list = prefs.getStringList('notifications') ?? [];
        bool exists = list.any((n) {
          final decoded = jsonDecode(n);
          return decoded['title'] == b['title'] && decoded['message'] == b['message'];
        });
        
        if (!exists) {
           _saveNotification(b);
        }

        // Check if active (less than 1 hour old)
        if (!shownDialog && b['createdAt'] != null) {
          DateTime? createdAt;
          if (b['createdAt'] is String) {
            createdAt = DateTime.tryParse(b['createdAt']);
          } else if (b['createdAt'] is Map) {
             // Handle Firestore Timestamp
             final int? seconds = b['createdAt']['_seconds'];
             if (seconds != null) {
               createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
             }
          }

          if (createdAt != null) {
            final now = DateTime.now();
            final difference = now.difference(createdAt.toLocal()); // Convert UTC to Local for comparison
            
            print('DEBUG: Broadcast "${b['title']}" Created: ${createdAt.toLocal()}, Now: $now, Diff (min): ${difference.inMinutes}');
            
            // Show dialog for broadcasts from the last 24 hours that haven't been shown yet
            if (difference.inHours < 24 && difference.inMinutes >= 0) {
              // Check if this broadcast was already shown
              final prefs = await SharedPreferences.getInstance();
              final shownBroadcasts = prefs.getStringList('shown_broadcasts') ?? [];
              
              if (!shownBroadcasts.contains(b['id'])) {
                print('DEBUG: Showing dialog for "${b['title']}"');
                _showBroadcastDialog(b);
                
                // Mark this broadcast as shown
                shownBroadcasts.add(b['id']);
                await prefs.setStringList('shown_broadcasts', shownBroadcasts);
                shownDialog = true;
              } else {
                print('DEBUG: Broadcast already shown before.');
              }
            } else {
               print('DEBUG: Skipping dialog. Too old or in future.');
            }
          }
        }
      }
    } catch (e) {
      print('Failed to fetch broadcasts: $e');
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('notifications') ?? [];
    setState(() {
      _notifications = list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveNotification(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('notifications') ?? [];
    
    final notification = {
      'title': data['title'],
      'message': data['message'],
      'region': data['region'],
      'priority': data['priority'],
      'time': DateTime.now().toIso8601String(),
      'read': false,
    };
    
    list.insert(0, jsonEncode(notification)); // Add to top
    if (list.length > 20) list.removeLast(); // Limit to 20
    
    await prefs.setStringList('notifications', list);
    
    if (mounted) {
      setState(() {
        _notifications = list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    }
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    );
  }

  /// Show Volunteer Tasks
  void _showVolunteerTasks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Volunteer Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildTaskCard(
                      title: 'Medical Supply Delivery',
                      location: 'Andheri East',
                      priority: 'High',
                      status: 'Assigned',
                      priorityColor: AppTheme.primaryRed,
                    ),
                    _buildTaskCard(
                      title: 'Flood Relief Assistance',
                      location: 'Kurla West',
                      priority: 'Medium',
                      status: 'In Progress',
                      priorityColor: AppTheme.primaryOrange,
                    ),
                    _buildTaskCard(
                      title: 'Community Patrol',
                      location: 'Bandra',
                      priority: 'Low',
                      status: 'Completed',
                      priorityColor: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String location,
    required String priority,
    required String status,
    required Color priorityColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(priority, style: TextStyle(color: priorityColor, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.w500)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.volunteerAccent),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }








}
