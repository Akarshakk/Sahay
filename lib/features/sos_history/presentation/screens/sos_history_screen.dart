import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/websocket_service.dart';

/// SOS History Screen - Show previous SOS incidents and nearby active alerts
class SOSHistoryScreen extends ConsumerStatefulWidget {
  const SOSHistoryScreen({super.key});

  @override
  ConsumerState<SOSHistoryScreen> createState() => _SOSHistoryScreenState();
}

class _SOSHistoryScreenState extends ConsumerState<SOSHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myLogs = [];
  List<dynamic> _nearbyAlerts = [];
  bool _isLoadingMy = true;
  bool _isLoadingNearby = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _loadNearbyAlerts();
    _subscribeToSOSUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToSOSUpdates() {
    final ws = ref.read(webSocketServiceProvider);

    // Listen for new SOS alerts
    ws.onNewSOS((data) {
      if (mounted) {
        _loadNearbyAlerts();
        // Show a snackbar for new SOS
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🚨 New SOS Alert: ${data['data']?['userName'] ?? 'Someone'} needs help!'),
            backgroundColor: AppTheme.primaryRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(1); // Switch to nearby tab
              },
            ),
          ),
        );
      }
    });

    // Listen for SOS resolved
    ws.onSOSResolved((data) {
      if (mounted) {
        _loadNearbyAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ ${data['data']?['userName'] ?? 'Someone'} is now safe'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Subscribe to location-based SOS alerts
    final location = ref.read(currentLocationProvider).valueOrNull;
    if (location != null) {
      ws.subscribeToSOSAlerts(location.latitude, location.longitude);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getSOSHistory();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _myLogs = result['data'];
          _isLoadingMy = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading SOS history: $e');
      setState(() => _isLoadingMy = false);
    }
  }

  Future<void> _loadNearbyAlerts() async {
    try {
      final api = ref.read(apiServiceProvider);
      final location = ref.read(currentLocationProvider).valueOrNull;

      if (location != null) {
        final result = await api.getNearbySOSAlerts(
          latitude: location.latitude,
          longitude: location.longitude,
          radius: 10.0, // 10km radius
        );
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _nearbyAlerts = result['data'];
            _isLoadingNearby = false;
          });
        }
      } else {
        // Fallback to active alerts if no location
        final result = await api.getActiveSOSAlerts();
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            _nearbyAlerts = result['data'];
            _isLoadingNearby = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading nearby SOS alerts: $e');
      setState(() => _isLoadingNearby = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getCardColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SOS Alerts',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryRed,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('My SOS'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 8),
                  const Text('Nearby'),
                  if (_nearbyAlerts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_nearbyAlerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My SOS Tab
          _buildMySOSTab(),
          // Nearby Alerts Tab
          _buildNearbyAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildMySOSTab() {
    if (_isLoadingMy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myLogs.isEmpty) {
      return _buildEmptyState('No SOS History', Icons.history);
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myLogs.length,
        itemBuilder: (context, index) {
          final log = _myLogs[index];
          return _buildSOSItem(log, isNearby: false)
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideX(begin: -0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildNearbyAlertsTab() {
    if (_isLoadingNearby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nearbyAlerts.isEmpty) {
      return _buildEmptyState('No Active Alerts Nearby', Icons.check_circle);
    }

    return RefreshIndicator(
      onRefresh: _loadNearbyAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyAlerts.length,
        itemBuilder: (context, index) {
          final alert = _nearbyAlerts[index];
          return _buildSOSItem(alert, isNearby: true)
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideX(begin: -0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSItem(Map<String, dynamic> log, {bool isNearby = false}) {
    final type = log['type'] ?? 'Emergency';
    final location = log['address'] ?? 'Unknown Location';
    final userName = log['userName'] ?? 'Unknown';
    final userPhone = log['userPhone'] ?? '';
    final statusText = log['status'] ?? 'TRIGGERED';
    final createdAt =
        DateTime.tryParse(log['createdAt'] ?? '') ?? DateTime.now();

    Color statusColor = AppTheme.primaryRed;
    if (statusText == 'RESOLVED') {
      statusColor = AppTheme.primaryGreen;
    } else if (statusText == 'FALSE_ALARM') {
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: isNearby && statusText == 'TRIGGERED'
            ? [
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNearby) ...[
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '$type Alert',
                      style: TextStyle(
                        fontSize: isNearby ? 14 : 16,
                        fontWeight:
                            isNearby ? FontWeight.w500 : FontWeight.bold,
                        color: isNearby
                            ? AppTheme.getSecondaryTextColor(context)
                            : AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusText == 'TRIGGERED')
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 500.ms)
                              .then()
                              .fadeOut(duration: 500.ms),
                        Text(
                          statusText == 'TRIGGERED' ? 'ACTIVE' : statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Show call button for nearby active alerts
          if (isNearby &&
              statusText == 'TRIGGERED' &&
              userPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to show on map
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View on Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryRed,
                      side: const BorderSide(color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Call the person
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
