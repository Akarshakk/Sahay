import 'dart:async';
import 'dart:math';
import '../../../../core/models/incident_model.dart';
import '../../../../core/enums/app_enums.dart';

/// Result wrapper for repository operations
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final bool isOffline;

  RepositoryResult.success(this.data)
      : error = null,
        isSuccess = true,
        isOffline = false;

  RepositoryResult.error(this.error)
      : data = null,
        isSuccess = false,
        isOffline = false;

  RepositoryResult.offline(this.data)
      : error = null,
        isSuccess = true,
        isOffline = true;
}

/// Location class for deduplication logic
class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);

  /// Calculate distance in meters using Haversine formula
  double distanceTo(Location other) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(other.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
}

/// Incident Repository Interface
abstract class IIncidentRepository {
  Future<RepositoryResult<IncidentModel>> submitReport(IncidentModel incident);
  Future<RepositoryResult<IncidentModel?>> checkDuplicate(double latitude, double longitude);
  Future<List<IncidentModel>> getIncidents();
  Future<List<IncidentModel>> getPendingIncidents();
  Future<RepositoryResult<IncidentModel>> verifyIncident(String incidentId);
}

/// Mock Incident Repository with Deduplication Logic
class MockIncidentRepository implements IIncidentRepository {
  // Web-compatible: removed Connectivity dependency
  bool _isOnline = true;
  
  // Simulated database
  final List<IncidentModel> _incidents = [
    // Existing incidents for deduplication testing
    IncidentModel(
      id: 'incident-001',
      title: 'Armed Robbery',
      description: 'Armed robbery reported',
      type: IncidentType.police,
      severity: SeverityLevel.critical,
      latitude: 19.0760, // Mumbai coordinates
      longitude: 72.8777,
      reportedBy: '9876543210',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      status: IncidentStatus.pending,
      isSynced: true,
      mediaUrls: const [],
      verificationCount: 0,
    ),
    IncidentModel(
      id: 'incident-002',
      title: 'Medical Emergency',
      description: 'Heart attack emergency',
      type: IncidentType.medical,
      severity: SeverityLevel.critical,
      latitude: 19.0761, // ~10m from first incident
      longitude: 72.8778,
      reportedBy: '9876543211',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      status: IncidentStatus.pending,
      isSynced: true,
      mediaUrls: const [],
      verificationCount: 0,
    ),
    IncidentModel(
      id: 'incident-003',
      title: 'Fire Incident',
      description: 'Small kitchen fire',
      type: IncidentType.fire,
      severity: SeverityLevel.medium,
      latitude: 19.1200, // Different location
      longitude: 72.9000,
      reportedBy: '9876543212',
      reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      status: IncidentStatus.pending,
      isSynced: true,
      mediaUrls: const [],
      verificationCount: 0,
    ),
  ];

  // Offline storage simulation
  final List<IncidentModel> _offlineQueue = [];

  @override
  Future<RepositoryResult<IncidentModel>> submitReport(IncidentModel incident) async {
    // Web-compatible: assume online for demo
    final isOnline = _isOnline;

    if (isOnline) {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Add to "database"
      _incidents.add(incident);
      
      return RepositoryResult.success(incident);
    } else {
      // Save to offline queue
      final offlineIncident = incident.copyWith(isSynced: false);
      _offlineQueue.add(offlineIncident);
      
      return RepositoryResult.offline(offlineIncident);
    }
  }

  @override
  Future<RepositoryResult<IncidentModel?>> checkDuplicate(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final userLocation = Location(latitude, longitude);
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    // Check for incidents within 100m in last 5 minutes
    for (final incident in _incidents) {
      final incidentLocation = Location(incident.latitude, incident.longitude);
      final distance = userLocation.distanceTo(incidentLocation);
      
      if (distance <= 100 && incident.timestamp.isAfter(fiveMinutesAgo)) {
        return RepositoryResult.success(incident); // Duplicate found
      }
    }

    return RepositoryResult.success(null); // No duplicate
  }

  @override
  Future<List<IncidentModel>> getIncidents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_incidents)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<IncidentModel>> getPendingIncidents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _incidents
        .where((incident) => incident.status == IncidentStatus.pending && 
                            (incident.severity == SeverityLevel.low || incident.severity == SeverityLevel.medium))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<RepositoryResult<IncidentModel>> verifyIncident(String incidentId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) {
      return RepositoryResult.error('Incident not found');
    }

    // Update verification count
    final updatedIncident = _incidents[index].copyWith(
      verificationCount: _incidents[index].verificationCount + 1,
      status: _incidents[index].verificationCount + 1 >= 5 
          ? IncidentStatus.verified
          : IncidentStatus.pending,
    );

    _incidents[index] = updatedIncident;

    return RepositoryResult.success(updatedIncident);
  }

  // Helper: Get offline queue
  List<IncidentModel> getOfflineQueue() => List.from(_offlineQueue);

  // Helper: Sync offline queue (called when network restored)
  Future<void> syncOfflineQueue() async {
    for (final incident in _offlineQueue) {
      _incidents.add(incident.copyWith(isSynced: true));
    }
    _offlineQueue.clear();
  }
}
