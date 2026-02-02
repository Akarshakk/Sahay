import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../incidents/presentation/providers/incident_provider.dart';

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Incident Heatmap'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          if (incidents.isEmpty) {
            return const Center(child: Text('No incidents to display'));
          }
          return _HeatmapView(incidents: incidents);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _HeatmapView extends StatefulWidget {
  final List<IncidentModel> incidents;

  const _HeatmapView({required this.incidents});

  @override
  State<_HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<_HeatmapView> {
  @override
  Widget build(BuildContext context) {
    if (widget.incidents.isEmpty) {
      return const Center(child: Text('No data for heatmap'));
    }

    // Calculate bounds to fit all incidents
    final points = widget.incidents
        .map((i) => LatLng(i.latitude, i.longitude))
        .toList();
    
    // Add some padding to bounds if only 1 point
    if (points.length == 1) {
      points.add(LatLng(points.first.latitude + 0.01, points.first.longitude + 0.01));
      points.add(LatLng(points.first.latitude - 0.01, points.first.longitude - 0.01));
    }

    return Column(
      children: [
        _buildLegend(),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.sahay.app',
              ),
              // Overlay labels for context (hybrid view)
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.sahay.app',
                backgroundColor: Colors.transparent,
              ),
              MarkerLayer(
                markers: widget.incidents.map((incident) {
                  // Add slight jitter to separate overlapping points
                  final random = Random(incident.id.hashCode);
                  final latOffset = (random.nextDouble() - 0.5) * 0.0005; // ~50m variance
                  final lngOffset = (random.nextDouble() - 0.5) * 0.0005;
                  
                  return Marker(
                    point: LatLng(incident.latitude + latOffset, incident.longitude + lngOffset),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                         showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(_getIncidentIcon(incident.type), color: _getSeverityColor(incident.severity)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(incident.title, style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(incident.severity).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _getSeverityColor(incident.severity)),
                                      ),
                                      child: Text(
                                        incident.severity.name.toUpperCase(),
                                        style: TextStyle(
                                          color: _getSeverityColor(incident.severity),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      incident.type.name.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(incident.description, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(
                                  'Reported by: ${incident.reporterName ?? incident.reporterPhone ?? incident.reportedBy}',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Time: ${incident.reportedAt.toString().substring(0, 16)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Main Icon Container
                          Container(
                            decoration: BoxDecoration(
                              color: _getSeverityColor(incident.severity).withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _getIncidentIcon(incident.type),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          // Status Badge
                          if (incident.status == IncidentStatus.pending)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
                                ),
                                child: const Text(
                                  '!',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
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

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.police: return Icons.local_police;
      case IncidentType.fire: return Icons.local_fire_department;
      case IncidentType.medical: return Icons.medical_services;
      case IncidentType.disaster: return Icons.flood;
      case IncidentType.woman: return Icons.woman;
      case IncidentType.child: return Icons.child_care;
      case IncidentType.elderly: return Icons.elderly;
      case IncidentType.railway: return Icons.train;
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem('Critical', AppTheme.primaryRed),
          _legendItem('High', Colors.orange),
          _legendItem('Medium', Colors.amber),
          _legendItem('Low', Colors.green),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
