import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/incident_model.dart';

/// SOS History Screen - Show previous SOS incidents
class SOSHistoryScreen extends ConsumerWidget {
  const SOSHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SOS History',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed,
                  AppTheme.primaryRed.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total SOS', '7', Icons.emergency),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem('Resolved', '5', Icons.check_circle),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem('Pending', '2', Icons.pending),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 24),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', true),
                const SizedBox(width: 8),
                _buildFilterChip('Active', false),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', false),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', false),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // SOS History Items
          _buildSOSItem(
            title: 'Medical Emergency',
            date: '10 Jan 2026, 3:45 PM',
            location: 'Andheri West, Mumbai',
            status: IncidentStatus.resolved,
            severity: SeverityLevel.high,
            responseTime: '8 min',
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildSOSItem(
            title: 'Road Accident',
            date: '8 Jan 2026, 11:20 AM',
            location: 'Bandra Kurla Complex',
            status: IncidentStatus.inProgress,
            severity: SeverityLevel.critical,
            responseTime: 'Ongoing',
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildSOSItem(
            title: 'Fire Emergency',
            date: '5 Jan 2026, 9:15 PM',
            location: 'Powai, Mumbai',
            status: IncidentStatus.resolved,
            severity: SeverityLevel.critical,
            responseTime: '12 min',
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildSOSItem(
            title: 'Crime Alert',
            date: '3 Jan 2026, 7:30 PM',
            location: 'Colaba, Mumbai',
            status: IncidentStatus.resolved,
            severity: SeverityLevel.medium,
            responseTime: '15 min',
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 12),
          
          _buildSOSItem(
            title: 'Medical Emergency',
            date: '1 Jan 2026, 2:10 PM',
            location: 'Juhu, Mumbai',
            status: IncidentStatus.resolved,
            severity: SeverityLevel.high,
            responseTime: '10 min',
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      selectedColor: AppTheme.primaryRed,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.neutralGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSOSItem({
    required String title,
    required String date,
    required String location,
    required IncidentStatus status,
    required SeverityLevel severity,
    required String responseTime,
  }) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case IncidentStatus.resolved:
        statusColor = AppTheme.primaryGreen;
        statusText = 'Resolved';
        break;
      case IncidentStatus.inProgress:
        statusColor = AppTheme.primaryOrange;
        statusText = 'In Progress';
        break;
      case IncidentStatus.cancelled:
        statusColor = AppTheme.neutralGray;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = AppTheme.primaryRed;
        statusText = 'Pending';
    }
    
    Color severityColor;
    switch (severity) {
      case SeverityLevel.critical:
        severityColor = AppTheme.primaryRed;
        break;
      case SeverityLevel.high:
        severityColor = AppTheme.primaryOrange;
        break;
      case SeverityLevel.medium:
        severityColor = Colors.amber;
        break;
      case SeverityLevel.low:
        severityColor = AppTheme.primaryGreen;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.neutralGray.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutralGray.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.primaryRed.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutralGray.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer,
                size: 16,
                color: AppTheme.neutralGray.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                responseTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralGray.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
