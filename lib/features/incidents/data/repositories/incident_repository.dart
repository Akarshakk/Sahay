import 'dart:async';
import 'dart:math';
import '../../../../core/models/incident_model.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/services/api_service.dart';

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

/// API-based Incident Repository (connects to real Firestore backend)
class ApiIncidentRepository implements IIncidentRepository {
  final ApiService _api;

  ApiIncidentRepository(this._api);

  @override
  Future<RepositoryResult<IncidentModel>> submitReport(IncidentModel incident) async {
    try {
      final result = await _api.createIncident({
        'title': incident.title,
        'description': incident.description,
        'category': incident.type.name,
        'priority': _severityToPriority(incident.severity),
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'address': null,
        'mediaUrls': incident.mediaUrls,
      });

      if (result['success'] == true && result['data'] != null) {
        return RepositoryResult.success(_parseIncident(result['data']));
      }
      return RepositoryResult.error(result['message'] ?? 'Failed to submit');
    } catch (e) {
      return RepositoryResult.error(e.toString());
    }
  }

  @override
  Future<List<IncidentModel>> getIncidents() async {
    try {
      final result = await _api.getIncidents(limit: 50);
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        return data.map((item) => _parseIncident(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching incidents: $e');
      return [];
    }
  }

  @override
  Future<List<IncidentModel>> getPendingIncidents() async {
    try {
      final result = await _api.getIncidents(status: 'pending', limit: 50);
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        return data.map((item) => _parseIncident(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pending incidents: $e');
      return [];
    }
  }

  @override
  Future<RepositoryResult<IncidentModel?>> checkDuplicate(double latitude, double longitude) async {
    try {
      final result = await _api.getNearbyIncidents(
        latitude: latitude,
        longitude: longitude,
        radius: 100, // 100 meter radius for duplicate check
      );

      if (result['data'] != null && (result['data'] as List).isNotEmpty) {
        return RepositoryResult.success(_parseIncident(result['data'][0]));
      }
      return RepositoryResult.success(null);
    } catch (e) {
      return RepositoryResult.error(e.toString());
    }
  }

  @override
  Future<RepositoryResult<IncidentModel>> verifyIncident(String incidentId) async {
    try {
      final result = await _api.verifyIncident(incidentId);
      if (result['success'] == true && result['data'] != null) {
        return RepositoryResult.success(_parseIncident(result['data']));
      }
      return RepositoryResult.error(result['message'] ?? 'Failed to verify');
    } catch (e) {
      return RepositoryResult.error(e.toString());
    }
  }

  String _severityToPriority(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return 'critical';
      case SeverityLevel.high:
        return 'high';
      case SeverityLevel.medium:
        return 'medium';
      case SeverityLevel.low:
        return 'low';
    }
  }

  IncidentModel _parseIncident(Map<String, dynamic> data) {
    return IncidentModel(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Incident',
      description: data['description'] ?? '',
      type: _parseIncidentType(data['category']),
      severity: _parseSeverity(data['priority']),
      latitude: (data['location']?['latitude'] ?? 0).toDouble(),
      longitude: (data['location']?['longitude'] ?? 0).toDouble(),
      reportedBy: data['reporterId'] ?? '',
      reportedAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      timestamp: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      status: _parseStatus(data['status']),
      isSynced: true,
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      verificationCount: data['verificationCount'] ?? 0,
    );
  }

  IncidentType _parseIncidentType(String? category) {
    switch (category?.toLowerCase()) {
      case 'police':
        return IncidentType.police;
      case 'fire':
        return IncidentType.fire;
      case 'medical':
        return IncidentType.medical;
      case 'disaster':
        return IncidentType.disaster;
      default:
        return IncidentType.police;
    }
  }

  SeverityLevel _parseSeverity(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return SeverityLevel.critical;
      case 'high':
        return SeverityLevel.high;
      case 'medium':
        return SeverityLevel.medium;
      case 'low':
        return SeverityLevel.low;
      default:
        return SeverityLevel.medium;
    }
  }

  IncidentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return IncidentStatus.pending;
      case 'verified':
        return IncidentStatus.verified;
      case 'in_progress':
        return IncidentStatus.inProgress;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'false_alarm':
        return IncidentStatus.falseAlarm;
      default:
        return IncidentStatus.pending;
    }
  }
}
