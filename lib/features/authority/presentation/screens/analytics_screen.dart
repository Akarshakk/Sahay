import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          if (incidents.isEmpty) {
            return const Center(child: Text('No data available'));
          }
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
    // Calculate stats
    final total = incidents.length;
    final critical = incidents.where((i) => i.severity == SeverityLevel.critical).length;
    final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).length;
    
    // Type distribution
    final Map<IncidentType, int> typeStats = {};
    for (var i in incidents) {
      typeStats[i.type] = (typeStats[i.type] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(child: _buildStatCard('Total\nIncidents', total.toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Critical\nAlerts', critical.toString(), Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Resolved\nCases', resolved.toString(), Colors.green)),
          ],
        ),
        const SizedBox(height: 24),

        // Severity Distribution
        const Text('Severity Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSeverityChart(incidents, total),
        
        const SizedBox(height: 24),

        // Type Breakdown
        const Text('Incident Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...typeStats.entries.map((e) => _buildTypeBar(e.key, e.value, total)).toList(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChart(List<IncidentModel> incidents, int total) {
    if (total == 0) return const SizedBox();
    
    final counts = {
      SeverityLevel.critical: incidents.where((i) => i.severity == SeverityLevel.critical).length,
      SeverityLevel.high: incidents.where((i) => i.severity == SeverityLevel.high).length,
      SeverityLevel.medium: incidents.where((i) => i.severity == SeverityLevel.medium).length,
      SeverityLevel.low: incidents.where((i) => i.severity == SeverityLevel.low).length,
    };

    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildTypeBar(IncidentType type, int count, int total) {
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('$count (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            color: AppTheme.authorityAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
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
}
