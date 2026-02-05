import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/user_model.dart' as user_model;
import '../../../../core/models/incident_model.dart';
import '../../../../core/services/audit_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';
import '../../../feed/presentation/screens/community_feed_screen.dart';
import '../../../authority/presentation/screens/heatmap_screen.dart';
import '../../../authority/presentation/screens/analytics_screen.dart';
import '../../../authority/presentation/screens/broadcast_screen.dart';
import '../../../authority/presentation/screens/resources_screen.dart';
import '../../../authority/presentation/screens/manage_tasks_screen.dart';
import 'package:intl/intl.dart';

/// Authority Dashboard - Command Center View
/// Features: Real-time incident feed (Command Center), Navigation to specialized screens
class AuthorityDashboardScreen extends ConsumerStatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  ConsumerState<AuthorityDashboardScreen> createState() => _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends ConsumerState<AuthorityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(incidentListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final incidentsAsync = ref.watch(incidentListProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildQuickAccessMenu(context),
            _buildStatsOverview(incidentsAsync),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                   const Icon(Icons.radio_button_checked, color: Colors.red, size: 16),
                   const SizedBox(width: 8),
                   const Text('LIVE INCIDENT FEED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   const Spacer(),
                   IconButton(
                     icon: const Icon(Icons.refresh, size: 20, color: AppTheme.neutralGray),
                     onPressed: () => ref.refresh(incidentListProvider),
                   ),
                ],
              ),
            ),
            Expanded(
              child: _buildLiveFeed(incidentsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user_model.User? user) {
    final registeredArea = user?.state ?? 'All Areas';
    
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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Command Center',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.name ?? 'Authority',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      registeredArea,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessMenu(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMenuButton(context, 'Verify\nCommunity', Icons.people, Colors.blue, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen(canVerify: true)))),
          _buildMenuButton(context, 'Heatmap', Icons.map, Colors.purple, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeatmapScreen()))),
          _buildMenuButton(context, 'Broadcast', Icons.campaign, Colors.orange, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen()))),
          _buildMenuButton(context, 'Analytics', Icons.analytics, Colors.teal, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
          _buildMenuButton(context, 'Resources', Icons.inventory, Colors.indigo, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()))),
          _buildMenuButton(context, 'Manage\nTasks', Icons.assignment, Colors.purple, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthorityManageTasksScreen()))),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(AsyncValue<List<IncidentModel>> incidentsAsync) {
    return incidentsAsync.when(
      data: (incidents) {
        final active = incidents.where((i) => i.status != IncidentStatus.resolved).length;
        final critical = incidents.where((i) => i.severity == SeverityLevel.critical).length;
        final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(child: _buildStatCard(icon: Icons.warning_amber_rounded, label: 'Active', value: active.toString(), color: AppTheme.primaryRed)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(icon: Icons.flash_on, label: 'Critical', value: critical.toString(), color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(icon: Icons.check_circle_outline, label: 'Resolved', value: resolved.toString(), color: AppTheme.primaryGreen)),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_,__) => const SizedBox(),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.neutralGray)),
        ],
      ),
    );
  }

  Widget _buildLiveFeed(AsyncValue<List<IncidentModel>> incidentsAsync) {
    return incidentsAsync.when(
      data: (incidentList) {
        if (incidentList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: AppTheme.primaryGreen.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No Active Incidents', style: TextStyle(fontSize: 16, color: AppTheme.neutralGray)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: incidentList.length,
          itemBuilder: (context, index) {
            final incident = incidentList[index];
            return _buildIncidentCard(incident).animate().fadeIn(delay: (index * 50).ms);
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    incident.type.name.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: severityColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4, 
                    height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    incident.severity.name.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: severityColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(incident.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  incident.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(incident.status)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(incident.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (incident.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(incident.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}', 
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Expanded(
                child: Text('Reported by: ${incident.reporterName ?? incident.reporterPhone ?? incident.reportedBy}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(_formatTime(incident.reportedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showIncidentDetails(incident),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.authorityAccent,
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showDispatchDialog(incident),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.authorityAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dispatch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical: return AppTheme.primaryRed;
      case SeverityLevel.high: return Colors.orange;
      case SeverityLevel.medium: return Colors.amber;
      case SeverityLevel.low: return Colors.green;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending: return Colors.orange;
      case IncidentStatus.verified: return Colors.blue;
      case IncidentStatus.inProgress: return Colors.purple;
      case IncidentStatus.resolved: return Colors.green;
      case IncidentStatus.falseAlarm: return Colors.grey;
      case IncidentStatus.assigned: return Colors.indigo;
      case IncidentStatus.cancelled: return Colors.black54;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.police: return Icons.local_police;
      case IncidentType.fire: return Icons.local_fire_department;
      case IncidentType.medical: return Icons.medical_services;
      case IncidentType.disaster: return Icons.flood;
      default: return Icons.warning; // Default for others
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  void _showIncidentDetails(IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(incident.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(incident.description),
            const SizedBox(height: 16),
            const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${incident.latitude}, ${incident.longitude}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.authorityAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDispatchDialog(IncidentModel incident) {
    // Audit log
    ref.read(auditServiceProvider).logAction(
      userId: ref.read(authControllerProvider)?.id ?? 'unknown',
      userName: ref.read(authControllerProvider)?.name ?? 'Authority',
      userRole: 'authority',
      actionType: AuditActionType.dispatch,
      actionDescription: 'Dispatched to incident: ${incident.title}',
      metadata: {'incidentId': incident.id}, // Using correct parameter matching AuditService
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resources dispatched to incident location')),
    );
  }
}
