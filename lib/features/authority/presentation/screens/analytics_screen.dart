import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppTheme.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(incidentListProvider),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          return _AnalyticsView(incidents: incidents);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  final List<IncidentModel> incidents;

  const _AnalyticsView({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate real stats from live data
    final total = incidents.length;
    final critical = incidents.where((i) => i.severity == SeverityLevel.critical).length;
    final high = incidents.where((i) => i.severity == SeverityLevel.high).length;
    final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).length;
    final pending = incidents.where((i) => i.status == IncidentStatus.pending).length;
    final inProgress = incidents.where((i) => i.status == IncidentStatus.inProgress).length;
    
    // Type distribution from real data
    final Map<IncidentType, int> typeStats = {};
    for (var i in incidents) {
      typeStats[i.type] = (typeStats[i.type] ?? 0) + 1;
    }

    // Calculate real crisis patterns (incidents per day over last 7 days)
    final dailyData = _calculateDailyIncidents(incidents);
    
    // Calculate hourly pattern from real data
    final hourlyData = _calculateHourlyPattern(incidents);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Response Time Analytics Section (calculated from incident timestamps)
        _buildSectionHeader(context, 'Response Statistics', Icons.timer_outlined),
        const SizedBox(height: 12),
        _buildResponseStats(context, incidents),
        const SizedBox(height: 24),

        // Crisis Pattern Section - REAL DATA
        _buildSectionHeader(context, 'Crisis Patterns (Last 7 Days)', Icons.show_chart),
        const SizedBox(height: 12),
        _buildCrisisPatternChart(context, dailyData),
        const SizedBox(height: 24),

        // Hourly Activity Pattern - REAL DATA
        _buildSectionHeader(context, 'Hourly Activity Pattern', Icons.access_time),
        const SizedBox(height: 12),
        _buildHourlyActivityChart(context, hourlyData),
        const SizedBox(height: 24),

        // Status Distribution - REAL DATA
        _buildSectionHeader(context, 'Status Distribution', Icons.pie_chart_outline),
        const SizedBox(height: 12),
        _buildStatusCards(context, resolved, inProgress, pending, total),
        const SizedBox(height: 24),

        // Summary Cards
        _buildSectionHeader(context, 'Incident Summary', Icons.dashboard_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Total\nIncidents', total.toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Critical\nAlerts', critical.toString(), Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'High\nPriority', high.toString(), Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),

        // Severity Distribution - REAL DATA
        _buildSectionHeader(context, 'Severity Distribution', Icons.bar_chart),
        const SizedBox(height: 12),
        _buildSeverityChart(context, incidents, total),
        
        const SizedBox(height: 24),

        // Type Breakdown - REAL DATA
        _buildSectionHeader(context, 'Incident Types', Icons.category_outlined),
        const SizedBox(height: 12),
        if (typeStats.isNotEmpty)
          ...typeStats.entries.map((e) => _buildTypeBar(context, e.key, e.value, total > 0 ? total : 1)),
        if (typeStats.isEmpty)
          _buildEmptyPlaceholder(context, 'No incident type data yet'),
        
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn();
  }

  /// Calculate incidents per day for the last 7 days from REAL DATA
  Map<String, int> _calculateDailyIncidents(List<IncidentModel> incidents) {
    final now = DateTime.now();
    final Map<String, int> dailyData = {};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = dayNames[date.weekday - 1];
      dailyData[dayName] = 0;
    }
    
    // Count incidents per day
    for (var incident in incidents) {
      final incidentDate = incident.timestamp;
      final diff = now.difference(incidentDate).inDays;
      if (diff >= 0 && diff < 7) {
        final dayName = dayNames[incidentDate.weekday - 1];
        dailyData[dayName] = (dailyData[dayName] ?? 0) + 1;
      }
    }
    
    return dailyData;
  }

  /// Calculate hourly pattern from REAL DATA
  List<int> _calculateHourlyPattern(List<IncidentModel> incidents) {
    final hourlyData = List.filled(24, 0);
    
    for (var incident in incidents) {
      final hour = incident.timestamp.hour;
      hourlyData[hour]++;
    }
    
    return hourlyData;
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.authorityAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.authorityAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseStats(BuildContext context, List<IncidentModel> incidents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate real response times from resolved incidents
    final resolvedIncidents = incidents.where((i) => i.status == IncidentStatus.resolved).toList();
    final totalIncidents = incidents.length;
    final resolvedCount = resolvedIncidents.length;
    final resolutionRate = totalIncidents > 0 ? (resolvedCount / totalIncidents * 100) : 0;
    
    // Calculate average time between reportedAt and now for pending incidents
    final pendingCount = incidents.where((i) => i.status == IncidentStatus.pending).length;
    
    return Row(
      children: [
        Expanded(child: _buildMetricCard(
          context, 
          'Resolution Rate',
          '${resolutionRate.toStringAsFixed(1)}%',
          Icons.check_circle_outline,
          Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(
          context,
          'Pending Incidents',
          pendingCount.toString(),
          Icons.schedule,
          Colors.red,
        )),
      ],
    ).animate().slideX(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisPatternChart(BuildContext context, Map<String, int> dailyData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final values = dailyData.values.toList();
    final maxVal = values.isEmpty ? 1 : (values.reduce((a, b) => a > b ? a : b));
    final totalIncidents = values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $totalIncidents incidents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              if (totalIncidents == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No recent data',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyData.entries.map((entry) {
                final height = maxVal > 0 ? (entry.value / maxVal) * 90 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height > 0 ? height : 4,
                          decoration: BoxDecoration(
                            color: entry.value > 0 
                                ? AppTheme.authorityAccent 
                                : (isDark ? Colors.grey[700] : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : AppTheme.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn();
  }

  Widget _buildHourlyActivityChart(BuildContext context, List<int> hourlyData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = hourlyData.isEmpty ? 1 : (hourlyData.reduce((a, b) => a > b ? a : b));
    final peakHour = hourlyData.indexOf(maxVal);
    final totalHourly = hourlyData.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                totalHourly > 0 ? Icons.warning_amber : Icons.info_outline,
                color: totalHourly > 0 ? Colors.orange : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  totalHourly > 0 
                      ? 'Peak: ${peakHour.toString().padLeft(2, '0')}:00'
                      : 'No data',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: totalHourly > 0 ? Colors.orange[700] : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (hour) {
                final value = hourlyData[hour];
                final height = maxVal > 0 ? (value / maxVal) * 60 : 0.0;
                final isPeak = hour == peakHour && value > 0;
                final isNight = hour >= 22 || hour < 6;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${hour.toString().padLeft(2, '0')}:00 - $value incidents',
                      child: Container(
                        height: height > 0 ? height : 2,
                        decoration: BoxDecoration(
                          color: value > 0
                              ? (isPeak 
                                  ? Colors.orange 
                                  : (isNight ? Colors.indigo : AppTheme.authorityAccent))
                              : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
              Text('06:00', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
              Text('12:00', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
              Text('18:00', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
              Text('24:00', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildLegendDot(Colors.indigo, 'Night'),
              _buildLegendDot(AppTheme.authorityAccent, 'Day'),
              _buildLegendDot(Colors.orange, 'Peak'),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 500.ms, delay: 100.ms).fadeIn();
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildStatusCards(BuildContext context, int resolved, int inProgress, int pending, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatusRow(context, 'Resolved', resolved, total, Colors.green),
          const SizedBox(height: 12),
          _buildStatusRow(context, 'In Progress', inProgress, total, Colors.orange),
          const SizedBox(height: 12),
          _buildStatusRow(context, 'Pending', pending, total, Colors.red),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 200.ms).fadeIn();
  }

  Widget _buildStatusRow(BuildContext context, String label, int count, int total, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChart(BuildContext context, List<IncidentModel> incidents, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (total == 0 || incidents.isEmpty) {
      return Container(
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey[700] : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey),
          ),
        ),
      );
    }
    
    final counts = {
      SeverityLevel.critical: incidents.where((i) => i.severity == SeverityLevel.critical).length,
      SeverityLevel.high: incidents.where((i) => i.severity == SeverityLevel.high).length,
      SeverityLevel.medium: incidents.where((i) => i.severity == SeverityLevel.medium).length,
      SeverityLevel.low: incidents.where((i) => i.severity == SeverityLevel.low).length,
    };

    return Column(
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.grey[700] : Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: counts.entries.map((e) {
                final flex = (e.value / total * 100).round();
                if (flex == 0) return const SizedBox();
                return Flexible(
                  flex: flex,
                  child: Container(color: _getSeverityColor(e.key)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: counts.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(e.key),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.key.name}: ${e.value}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : AppTheme.textDark,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeBar(BuildContext context, IncidentType type, int count, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              Text(
                '$count (${(pct * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppTheme.neutralGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              color: AppTheme.authorityAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
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
}
