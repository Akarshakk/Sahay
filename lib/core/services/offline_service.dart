import '../models/incident_model.dart';
import 'dart:developer' as developer;

/// Offline-First Service: Handles store-and-forward logic
/// Web-compatible stub - full functionality available on mobile
class OfflineService {
  static final OfflineService instance = OfflineService._internal();
  factory OfflineService() => instance;
  OfflineService._internal();

  final List<IncidentModel> _localIncidents = [];
  final bool _isOnline = true;

  static const String INCIDENT_BOX = 'incidents';
  static const String SYNC_TASK = 'sync_offline_data';

  Future<void> initialize() async {
    developer.log('OfflineService initialized (web mode)');
  }

  /// Save incident locally (offline-first)
  Future<void> saveIncidentLocally(IncidentModel incident) async {
    try {
      _localIncidents.add(incident);
      developer.log('Incident saved locally: ${incident.id}');
    } catch (e) {
      developer.log('Error saving incident locally: $e');
    }
  }

  /// Get all unsynced incidents
  List<IncidentModel> getUnsyncedIncidents() {
    return _localIncidents
        .where((incident) => !incident.isSynced)
        .toList();
  }

  /// Mark incident as synced
  Future<void> markAsSynced(String incidentId) async {
    final index = _localIncidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      final incident = _localIncidents[index];
      _localIncidents[index] = incident.copyWith(isSynced: true);
    }
  }

  /// Clear synced incidents (cleanup)
  Future<void> clearSyncedIncidents() async {
    _localIncidents.removeWhere((incident) => incident.isSynced);
  }
}
