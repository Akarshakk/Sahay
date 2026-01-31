import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/user_model.dart' as user_model;
import '../../../../core/models/incident_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';

/// Authority Dashboard - Command Center View
/// Features: Real-time incident feed, analytics, resource management, broadcast alerts
class AuthorityDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  
  const AuthorityDashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AuthorityDashboardScreen> createState() => _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends ConsumerState<AuthorityDashboardScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildStatsOverview(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user_model.User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.authorityAccent,
            AppTheme.authorityAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.name ?? 'Authority Officer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.warning_amber_rounded,
              label: 'Active',
              value: '12',
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_outlined,
              label: 'Resolved',
              value: '45',
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_outline,
              label: 'On Duty',
              value: '28',
              color: AppTheme.citizenAccent,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('Live Feed', 0, Icons.feed),
            const SizedBox(width: 8),
            _buildTab('Heatmap', 1, Icons.map),
            const SizedBox(width: 8),
            _buildTab('Broadcast', 2, Icons.campaign),
            const SizedBox(width: 8),
            _buildTab('Analytics', 3, Icons.analytics),
            const SizedBox(width: 8),
            _buildTab('Resources', 4, Icons.inventory),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.authorityAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.authorityAccent : AppTheme.neutralGray.withOpacity(0.2),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.authorityAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.neutralGray,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.neutralGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildLiveFeed();
      case 1:
        return _buildHeatmapView();
      case 2:
        return _buildBroadcastView();
      case 3:
        return _buildAnalyticsView();
      case 4:
        return _buildResources();
      default:
        return _buildLiveFeed();
    }
  }

  Widget _buildLiveFeed() {
    final incidents = ref.watch(incidentListProvider);

    return incidents.when(
      data: (incidentList) {
        if (incidentList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Incidents',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: incidentList.length,
          itemBuilder: (context, index) {
            final incident = incidentList[index];
            return _buildIncidentCard(incident).animate().fadeIn(delay: (index * 100).ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildIncidentCard(IncidentModel incident) {
    final severityColor = _getSeverityColor(incident.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_getIncidentIcon(incident.type), size: 16, color: severityColor),
                    const SizedBox(width: 6),
                    Text(
                      incident.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(incident.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  incident.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(incident.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            incident.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutralGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.neutralGray),
              const SizedBox(width: 4),
              Text(
                '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.neutralGray),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: AppTheme.neutralGray),
              const SizedBox(width: 4),
              Text(
                _formatTime(incident.reportedAt),
                style: const TextStyle(fontSize: 12, color: AppTheme.neutralGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.authorityAccent,
                    side: const BorderSide(color: AppTheme.authorityAccent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Dispatch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.authorityAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.layers,
                    size: 64,
                    color: AppTheme.authorityAccent.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Incident Heatmap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visualize incident density by area',
                    style: TextStyle(
                      color: AppTheme.neutralGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildHeatmapLegend(),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Low', Colors.green),
          _buildLegendItem('Medium', Colors.orange),
          _buildLegendItem('High', Colors.red),
          _buildLegendItem('Critical', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBroadcastView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.primaryRed],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.campaign, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Send Emergency Broadcast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alert all citizens in selected areas',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showBroadcastDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Create Broadcast'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Broadcasts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBroadcastItem('Flash Flood Warning', '2 hours ago', Icons.waves, Colors.blue),
          const SizedBox(height: 8),
          _buildBroadcastItem('Road Closure Alert', '5 hours ago', Icons.block, Colors.orange),
          const SizedBox(height: 8),
          _buildBroadcastItem('Safety Advisory', '1 day ago', Icons.info, Colors.green),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildBroadcastItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Broadcast'),
        content: const Text('Broadcast functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text(
            'Incident Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAnalyticsCard('Total Today', '28', Icons.today, AppTheme.citizenAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildAnalyticsCard('This Week', '156', Icons.date_range, AppTheme.primaryOrange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAnalyticsCard('Resolved', '89%', Icons.check_circle, AppTheme.primaryGreen)),
              const SizedBox(width: 12),
              Expanded(child: _buildAnalyticsCard('Avg Response', '12m', Icons.timer, AppTheme.authorityAccent)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incidents by Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildAnalyticsBar('Medical', 0.35, Colors.red),
                const SizedBox(height: 12),
                _buildAnalyticsBar('Fire', 0.2, Colors.orange),
                const SizedBox(height: 12),
                _buildAnalyticsBar('Police', 0.25, Colors.blue),
                const SizedBox(height: 12),
                _buildAnalyticsBar('Disaster', 0.1, Colors.purple),
                const SizedBox(height: 12),
                _buildAnalyticsBar('Other', 0.1, Colors.grey),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.neutralGray),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResources() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildResourceCard(
          'Police Units',
          '15 Available',
          Icons.local_police,
          AppTheme.citizenAccent,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Fire Services',
          '8 Available',
          Icons.local_fire_department,
          AppTheme.primaryRed,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Ambulances',
          '12 Available',
          Icons.local_hospital,
          AppTheme.primaryGreen,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Volunteers',
          '45 On Duty',
          Icons.people,
          AppTheme.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildResourceCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return AppTheme.primaryRed;
      case SeverityLevel.high:
        return AppTheme.primaryOrange;
      case SeverityLevel.medium:
        return const Color(0xFFFFA726);
      case SeverityLevel.low:
        return AppTheme.citizenAccent;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return AppTheme.primaryOrange;
      case IncidentStatus.verified:
        return AppTheme.citizenAccent;
      case IncidentStatus.assigned:
        return const Color(0xFF9C27B0);
      case IncidentStatus.inProgress:
        return const Color(0xFF2196F3);
      case IncidentStatus.resolved:
        return AppTheme.primaryGreen;
      case IncidentStatus.cancelled:
        return AppTheme.neutralGray;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.police:
        return Icons.local_police;
      case IncidentType.fire:
        return Icons.local_fire_department;
      case IncidentType.medical:
        return Icons.local_hospital;
      case IncidentType.disaster:
        return Icons.warning_amber_rounded;
      case IncidentType.woman:
        return Icons.woman;
      case IncidentType.child:
        return Icons.child_care;
      case IncidentType.elderly:
        return Icons.elderly;
      case IncidentType.railway:
        return Icons.train;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
