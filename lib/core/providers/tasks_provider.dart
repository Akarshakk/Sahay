import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

// Simple providers for task-related data
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  // Currently unused placeholder – keep for potential global task lists
  return [];
});

final getTasksByRegionProvider =
    FutureProvider.family<List<Task>, String>((ref, region) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTasksByRegion(region);
});

final getAssignedTasksProvider = FutureProvider<List<Task>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAssignedTasks();
});

// Tasks created by current authority (for CRUD in dashboard)
final getMyTasksProvider = FutureProvider<List<Task>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMyTasks();
});

final getMySubmissionsProvider =
    FutureProvider<List<TaskSubmission>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMySubmissions();
});

final getTaskSubmissionsProvider =
    FutureProvider.family<List<TaskSubmission>, String>((ref, taskId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTaskSubmissions(taskId);
});
