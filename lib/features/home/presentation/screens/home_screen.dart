import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:background_sms/background_sms.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/hardware_trigger_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:background_sms/background_sms.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import 'dart:ui';
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
import '../../../sos/presentation/screens/sos_countdown_screen.dart';
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
  bool _isTourChecked = false;

  // Keys for App Tour

  // Keys for App Tour
  final GlobalKey _sosKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _policeKey = GlobalKey();
  final GlobalKey _ambulanceKey = GlobalKey();
  final GlobalKey _fireKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();

  @override
  void initState() {
    print("DEBUG: HomeScreen initState");
    super.initState();
    _loadNotifications();
    // Hardware Trigger Listener - Navigate to SOS countdown screen
    HardwareTriggerService().onEmergencyTriggered = _triggerEmergencySOS;
    HardwareTriggerService().initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWebSocket();
    });
  }

  Future<void> _checkAndStartTour(BuildContext innerContext) async {
    print("DEBUG: _checkAndStartTour called");
    final prefs = await SharedPreferences.getInstance();
    // For debugging: Force tour if needed or check logic
    // await prefs.remove('hasSeenTour'); // Uncomment to reset for testing

    final hasSeenTour = prefs.getBool('hasSeenTour') ?? false;
    print("DEBUG: hasSeenTour = $hasSeenTour");

    // For testing: Show tour everytime
    // if (!hasSeenTour) {
    if (true) {
      print("DEBUG: Starting ShowCase");
      if (mounted) {
        // Ensure context is valid
        try {
          final List<GlobalKey> tourKeys = [
            _sosKey,
            _locationKey,
            _policeKey,
            _ambulanceKey,
            _fireKey
          ];

          // Community key is only for citizens
          if (widget.userRole == UserRole.citizen) {
            tourKeys.add(_communityKey);
          }

          ShowCaseWidget.of(innerContext).startShowCase(tourKeys);
          print("DEBUG: ShowCase started");
          await prefs.setBool('hasSeenTour', true);
        } catch (e) {
          print("DEBUG: Failed to start ShowCase: $e");
        }
      }
    }
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

      // Subscribe to SOS alerts for volunteers and authorities
      if (user.role == UserRole.volunteer || user.role == UserRole.authority) {
        final location = ref.read(currentLocationProvider).valueOrNull;
        if (location != null) {
          ws.subscribeToSOSAlerts(location.latitude, location.longitude);
        }

        // Listen for new SOS alerts
        ws.onNewSOS((data) {
          if (!mounted) return;
          _showSOSAlertDialog(data);
        });

        // Listen for SOS updates (including new messages)
        ws.onSOSUpdated((data) {
          if (!mounted) return;
          _showSOSUpdateSnackbar(data);
        });
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
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.primaryRed, size: 28),
            SizedBox(width: 12),
            Expanded(
                child: Text('EMERGENCY ALERT',
                    style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Alert',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(data['message'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Region: ${data['region']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic)),
            Text('Priority: ${data['priority']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
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

  void _showSOSAlertDialog(dynamic data) {
    final sosData = data is Map ? data : {};
    final String sosId = sosData['id']?.toString() ?? 'Unknown';
    final String type = sosData['type']?.toString() ?? 'EMERGENCY';
    final String? message = sosData['message']?.toString();
    final String? address = sosData['address']?.toString();
    final double? latitude = sosData['latitude'] is num
        ? (sosData['latitude'] as num).toDouble()
        : null;
    final double? longitude = sosData['longitude'] is num
        ? (sosData['longitude'] as num).toDouble()
        : null;
    final String? userName = sosData['userName']?.toString();
    final String? userPhone = sosData['userPhone']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.sos, color: AppTheme.primaryRed, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'SOS ALERT!',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info if available
              if (userName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Emergency type
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Message if present
              if (message != null && message.isNotEmpty) ...[
                const Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Location
              const Text(
                'Location:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address != null && address.isNotEmpty)
                      Text(address, style: const TextStyle(fontSize: 14)),
                    if (latitude != null && longitude != null)
                      Text(
                        'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'SOS ID: $sosId',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          if (userPhone != null)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final Uri phoneUri = Uri(scheme: 'tel', path: userPhone);
                try {
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                } catch (e) {
                  debugPrint('Failed to call: $e');
                }
              },
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to map or location - can be enhanced
              if (latitude != null && longitude != null) {
                _openMapLocation(latitude, longitude, address);
              }
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('View Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSOSUpdateSnackbar(dynamic data) {
    final sosData = data is Map ? data : {};
    final String? message = sosData['message']?.toString();
    final String action = sosData['action']?.toString() ?? 'Update';

    String snackMessage = 'SOS Alert Updated';
    if (action == 'MESSAGE_SENT' && message != null) {
      snackMessage =
          'New SOS Message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}';
    } else if (action == 'MARKED_SAFE') {
      snackMessage = 'User has marked themselves as safe';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sos, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(snackMessage)),
          ],
        ),
        backgroundColor: action == 'MARKED_SAFE'
            ? AppTheme.primaryGreen
            : AppTheme.primaryRed,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _showSOSAlertDialog(data);
          },
        ),
      ),
    );
  }

  Future<void> _openMapLocation(double lat, double lng, String? address) async {
    final Uri mapsUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location: ${address ?? '$lat, $lng'}')),
        );
      }
    }
  }

  @override
  void dispose() {
    HardwareTriggerService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: HomeScreen build");
    return ShowCaseWidget(
      blurValue: 1,
      autoPlay: false,
      builder: (innerContext) {
        final user = ref.watch(authControllerProvider);

        if (!_isTourChecked) {
          _isTourChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndStartTour(innerContext);
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          drawer: _buildDrawer(user),
          body: Stack(
            children: [
              // Background Gradient Element
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBrand.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBrand.withOpacity(0.2),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildEmergencyBanner(),
                            const SizedBox(height: 24),
                            _buildShowcase(
                              innerContext,
                              _locationKey,
                              'Your Location',
                              'View your live location and address. This helps rescuers find you.',
                              _buildLocationDisplay(),
                            ),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildServiceGrid(innerContext),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildShowcase(
            innerContext,
            _sosKey,
            'Emergency SOS',
            'Press and hold for 3 seconds to send an immediate distress alert.',
            _buildSOSButton(),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon:
                Icon(Icons.menu_rounded, color: AppTheme.getTextColor(context)),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            ref.watch(authControllerProvider)?.name ?? 'Sahay',
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: AppTheme.getTextColor(context)),
            onPressed: () => _showNotificationsPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyBanner() {
    final roleText = _getRoleBannerText();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.crisisRed, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.crisisRed.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Emergency Assistance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  roleText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
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
              icon: Icons.history,
              label: 'SOS History',
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SOSHistoryScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Showcase(
              key: _communityKey,
              title: 'Community',
              description: 'Connect with neighbors and see local updates.',
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
              MaterialPageRoute(
                  builder: (context) => const VolunteerDashboardScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.volunteerAccent,
                    AppTheme.volunteerAccent.withOpacity(0.7)
                  ],
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
                    child: const Icon(Icons.dashboard,
                        color: Colors.white, size: 24),
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
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
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
                      builder: (context) =>
                          const VolunteerTasksDetailedScreen(),
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
                    MaterialPageRoute(
                        builder: (context) =>
                            const CommunityFeedScreen(canVerify: true)),
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
                    MaterialPageRoute(
                        builder: (context) => const ResourcesScreen()),
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
              MaterialPageRoute(
                  builder: (context) => const AuthorityDashboardScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.authorityAccent,
                    AppTheme.authorityAccent.withOpacity(0.7)
                  ],
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
                    child:
                        const Icon(Icons.shield, color: Colors.white, size: 24),
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
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
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
                    MaterialPageRoute(
                        builder: (context) =>
                            const CommunityFeedScreen(canVerify: true)),
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
                    MaterialPageRoute(
                        builder: (context) => const ResourcesScreen()),
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
                    MaterialPageRoute(
                        builder: (context) => const HeatmapScreen()),
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
                    MaterialPageRoute(
                        builder: (context) => const BroadcastScreen()),
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
                    MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen()),
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
          color: AppTheme.getCardColor(context),
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
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCompactServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildServiceGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Emergency Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            children: [
              _buildShowcase(
                context,
                _policeKey,
                'Police',
                'Report crimes/assistance',
                _buildCompactServiceCard(
                  title: 'Police',
                  icon: Icons.local_police,
                  color: const Color(0xFF1E88E5),
                  onTap: () => _showIncidentReportDialog(IncidentType.police),
                ),
              ),
              _buildShowcase(
                context,
                _fireKey,
                'Fire',
                'Fire emergencies',
                _buildCompactServiceCard(
                  title: 'Fire',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFE53935),
                  onTap: () => _showIncidentReportDialog(IncidentType.fire),
                ),
              ),
              _buildShowcase(
                context,
                _ambulanceKey,
                'Medical',
                'Medical help',
                _buildCompactServiceCard(
                  title: 'Medical',
                  icon: Icons.medical_services,
                  color: const Color(0xFFE53935),
                  onTap: () => _showIncidentReportDialog(IncidentType.medical),
                ),
              ),
              _buildCompactServiceCard(
                title: 'Disaster',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                onTap: () => _showIncidentReportDialog(IncidentType.disaster),
              ),
              _buildCompactServiceCard(
                title: 'Woman',
                icon: Icons.woman,
                color: Colors.pink,
                onTap: () => _showIncidentReportDialog(IncidentType.woman),
              ),
              _buildCompactServiceCard(
                title: 'Child',
                icon: Icons.child_care,
                color: Colors.teal,
                onTap: () => _showIncidentReportDialog(IncidentType.child),
              ),
              _buildCompactServiceCard(
                title: 'Elderly',
                icon: Icons.elderly,
                color: Colors.brown,
                onTap: () => _showIncidentReportDialog(IncidentType.elderly),
              ),
              _buildCompactServiceCard(
                title: 'Railway',
                icon: Icons.train,
                color: Colors.indigo,
                onTap: () => _showIncidentReportDialog(IncidentType.railway),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisplay() {
    final locationAsync = ref.watch(currentLocationProvider);

    return GlassContainer(
      color: AppTheme.getCardColor(context),
      opacity: AppTheme.isDarkMode(context) ? 0.8 : 0.7,
      border: AppTheme.isDarkMode(context)
          ? Border.all(color: Colors.white.withOpacity(0.1))
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrand.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.primaryBrand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                locationAsync.when(
                  data: (location) => Text(
                    location?.address ?? 'Location unavailable',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primaryBrand),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Locating...',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Text(
                    'Tap to enable location',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.alertOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryBrand),
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
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
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
    // Map IncidentType to EmergencyType
    EmergencyType getEmergencyType() {
      switch (type) {
        case IncidentType.police:
          return EmergencyType.police;
        case IncidentType.fire:
          return EmergencyType.fire;
        case IncidentType.medical:
          return EmergencyType.medical;
        case IncidentType.disaster:
          return EmergencyType.disaster;
        case IncidentType.woman:
          return EmergencyType.women;
        case IncidentType.child:
          return EmergencyType.child;
        case IncidentType.elderly:
          return EmergencyType.elderly;
        case IncidentType.railway:
          return EmergencyType.railway;
        default:
          return EmergencyType.police;
      }
    }

    final emergencyType = getEmergencyType();

    // Show dialog with options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${type.name.toUpperCase()} Services',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to do?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Report Incident Option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          IncidentReportFormScreen(incidentType: type),
                    ),
                  );
                },
                icon: const Icon(Icons.report),
                label: const Text('Report an Incident'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryRed),
                  foregroundColor: AppTheme.primaryRed,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SOS Option
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SOSCountdownScreen(
                        emergencyType: emergencyType,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.sos),
                label: Text('SOS - Call ${emergencyType.number}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger Emergency SOS - Navigate to countdown screen
  Future<void> _triggerEmergencySOS() async {
    // Navigate to the SOS countdown screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SOSCountdownScreen(),
      ),
    );
  }

  /// Legacy SOS Dialog - Shows emergency call/SMS options
  Future<void> _showEmergencyOptions() async {
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
              child: const Icon(Icons.emergency,
                  color: AppTheme.primaryRed, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Emergency SOS',
                style: TextStyle(fontWeight: FontWeight.bold)),
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

            const Text('Select emergency service to call:',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text(number,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.call, size: 20),
          ],
        ),
      ),
    );
  }

  /// Make emergency phone call (Direct)
  Future<void> _makeEmergencyCall(String number) async {
    try {
      // Try direct call first
      bool? res = await FlutterPhoneDirectCaller.callNumber(number);
      if (res == true) return;
    } catch (e) {
      debugPrint('Direct call failed: $e');
    }

    // Fallback to URL Launcher
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

  /// Send emergency SMS with location (Direct/Background)
  Future<void> _sendEmergencySMS(LocationData? location) async {
    final String message = location != null
        ? 'EMERGENCY SOS! I need help. My location: ${location.address} (${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})'
        : 'EMERGENCY SOS! I need help. Please contact me immediately.';

    // Default emergency contacts (Police control room)
    const String emergencyNumber = '112';

    // Check permission
    if (await Permission.sms.isGranted) {
      try {
        final result = await BackgroundSms.sendMessage(
          phoneNumber: emergencyNumber,
          message: message,
        );
        if (result == SmsStatus.sent) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('SMS Sent Automatically'),
                backgroundColor: Colors.green),
          );
          return;
        }
      } catch (e) {
        debugPrint('Direct SMS failed: $e');
      }
    }

    // Fallback to URL Launcher
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

      // 3. Send SMS automatically
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

  /// Start SOS Countdown Dialog
  void _startSOSCountdown() {
    int countdown = 5;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Initialize timer once
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 1) {
              setState(() => countdown--);
            } else {
              t.cancel();
              Navigator.pop(context);
              _executeSOSSequence();
            }
          });

          return AlertDialog(
            backgroundColor: AppTheme.primaryRed,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'SOS TRIGGERED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sending alerts in',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 16),
                Text(
                  '$countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(target: countdown.toDouble()).scale(
                      begin: const Offset(1.5, 1.5),
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryRed,
                    ),
                    child: const Text('CANCEL SOS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => timer?.cancel());
  }

  /// Execute SOS Sequence (API + SMS + Call)
  Future<void> _executeSOSSequence() async {
    // 1. Trigger API (Police)
    await _submitEmergencySOS();

    // Get location for SMS
    final location = ref.read(currentLocationProvider).valueOrNull;

    // 2. Send SMS to Contacts
    if (mounted) {
      _sendEmergencySMS(location);
    }

    // 3. Call Police automatically
    final user = ref.read(authControllerProvider);
    final userId = user?.id ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final policeNum = prefs.getString('${userId}_sos_police') ?? '112';

    _makeEmergencyCall(policeNum);
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
        color: AppTheme.getBackgroundColor(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone Number
                  Text(
                    '+91 ${user?.phone ?? 'Not logged in'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(context),
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
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
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
                    MaterialPageRoute(
                        builder: (context) => const AuthorityDashboardScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const EContactScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const SOSHistoryScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
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
                  MaterialPageRoute(
                      builder: (context) => const TopQuestionsScreen()),
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
        color: isSelected
            ? AppTheme.primaryRed
            : AppTheme.primaryRed.withOpacity(0.7),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.getTextColor(context),
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
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
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
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _notifications
                        .map((n) => _buildNotificationItem(
                              icon: Icons.warning_amber,
                              title: n['title'] ?? 'Alert',
                              subtitle: n['message'] ?? '',
                              time: _formatTime(
                                  DateTime.tryParse(n['time'] ?? '') ??
                                      DateTime.now()),
                              color: (n['priority'] == 'High' ||
                                      n['priority'] == 'Critical')
                                  ? AppTheme.primaryRed
                                  : AppTheme.primaryOrange,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchMissedBroadcasts(String region) async {
    try {
      final broadcasts =
          await ref.read(apiServiceProvider).getBroadcasts(region);
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

      print(
          'DEBUG: Fetched ${broadcasts.length} broadcasts for region $region');

      for (var b in broadcasts) {
        // Check if already saved
        final prefs = await SharedPreferences.getInstance();
        final List<String> list = prefs.getStringList('notifications') ?? [];
        bool exists = list.any((n) {
          final decoded = jsonDecode(n);
          return decoded['title'] == b['title'] &&
              decoded['message'] == b['message'];
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
            final difference = now.difference(
                createdAt.toLocal()); // Convert UTC to Local for comparison

            print(
                'DEBUG: Broadcast "${b['title']}" Created: ${createdAt.toLocal()}, Now: $now, Diff (min): ${difference.inMinutes}');

            // Show dialog for broadcasts from the last 24 hours that haven't been shown yet
            if (difference.inHours < 24 && difference.inMinutes >= 0) {
              // Check if this broadcast was already shown
              final prefs = await SharedPreferences.getInstance();
              final shownBroadcasts =
                  prefs.getStringList('shown_broadcasts') ?? [];

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
      _notifications =
          list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
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
        _notifications =
            list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
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
      trailing:
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(priority,
                      style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
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
                Text('Status: $status',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.volunteerAccent),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcase(BuildContext context, GlobalKey key, String title,
      String description, Widget child) {
    return Showcase.withWidget(
      key: key,
      targetPadding: const EdgeInsets.all(4),
      container: Builder(
        builder: (_) => _TourTooltip(
          title: title,
          description: description,
          onNext: () {
            print("DEBUG: Tour Next Clicked");
            try {
              ShowCaseWidget.of(context).next();
            } catch (e) {
              print("DEBUG: Tour Next Error: $e");
            }
          },
          onSkip: () {
            print("DEBUG: Tour Skip Clicked");
            try {
              ShowCaseWidget.of(context).dismiss();
            } catch (e) {
              print("DEBUG: Tour Skip Error: $e");
            }
          },
        ),
      ),
      child: child,
    );
  }
}

class _TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TourTooltip({
    required this.title,
    required this.description,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child:
                      const Text('Skip', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
