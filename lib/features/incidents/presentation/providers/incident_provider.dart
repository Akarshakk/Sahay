import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';

part 'incident_provider.g.dart';

/// Repository Provider
@riverpod
IIncidentRepository incidentRepository(IncidentRepositoryRef ref) {
  return MockIncidentRepository();
}

/// Incident List Provider
@riverpod
class IncidentList extends _$IncidentList {
  @override
  Future<List<IncidentModel>> build() async {
    final repository = ref.read(incidentRepositoryProvider);
    return await repository.getIncidents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(incidentRepositoryProvider);
      return await repository.getIncidents();
    });
  }
}

/// Pending Incidents Provider (for Volunteer Feed)
@riverpod
class PendingIncidentList extends _$PendingIncidentList {
  @override
  Future<List<IncidentModel>> build() async {
    final repository = ref.read(incidentRepositoryProvider);
    return await repository.getPendingIncidents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(incidentRepositoryProvider);
      return await repository.getPendingIncidents();
    });
  }
}

/// Incident Controller for Actions
@riverpod
class IncidentController extends _$IncidentController {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  Future<RepositoryResult<IncidentModel>> submitReport({
    required IncidentModel incident,
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(incidentRepositoryProvider);
    final result = await repository.submitReport(incident);

    // Refresh incident list
    ref.invalidate(incidentListProvider);

    state = const AsyncData(null);
    return result;
  }

  /// Check for duplicate incidents nearby
  Future<RepositoryResult<IncidentModel?>> checkDuplicate(double latitude, double longitude) async {
    final repository = ref.read(incidentRepositoryProvider);
    return await repository.checkDuplicate(latitude, longitude);
  }

  Future<RepositoryResult<IncidentModel>> verifyIncident(String incidentId) async {
    final repository = ref.read(incidentRepositoryProvider);
    final result = await repository.verifyIncident(incidentId);

    // Refresh lists
    ref.invalidate(pendingIncidentListProvider);
    ref.invalidate(incidentListProvider);

    return result;
  }
}
