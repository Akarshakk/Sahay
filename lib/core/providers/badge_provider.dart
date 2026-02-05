import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../models/task_model.dart';
import 'tasks_provider.dart';

// Defines the base badges with logic to calculate status
final badgesProvider = FutureProvider<List<AchievementBadge>>((ref) async {
  // 1. Get submissions
  final submissions = await ref.watch(getMySubmissionsProvider.future);
  
  // 2. We need task details to calculate points and categories
  // Since we don't have a direct "getTasksByIds" API yet, we'll fetch region tasks 
  // and match them. Ideally backend would provide a "getBadgeProgress" endpoint.
  // For now, we'll rely on what we have.
  // NOTE: This assumes we can find the tasks in the "general" region list.
  // If tasks are archived or in other regions, we might miss them. 
  // For this hackathon/demo scope, this is acceptable.
  List<Task> allKnownTasks = [];
  try {
    allKnownTasks = await ref.read(getTasksByRegionProvider('general').future);
  } catch (e) {
    // Silently fail if we can't fetch tasks, badges will just rely on submission counts
    print('Error fetching tasks for badges: $e');
  }

  // Helper to find task
  Task? findTask(String taskId) {
    try {
      return allKnownTasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  // METRICS
  final completedCount = submissions.where((s) => s.status == 'verified').length;
  final submittedCount = submissions.length;
  
  int totalPoints = 0;
  for (final sub in submissions) {
    if (sub.status == 'verified') {
      final task = findTask(sub.taskId);
      if (task != null) {
        totalPoints += task.rewardPoints;
      }
    }
  }

  int nightTasks = 0;
  for (final sub in submissions) {
    final hour = sub.createdAt.hour;
    if (hour >= 20 || hour <= 5) {
      nightTasks++;
    }
  }
  
  // BADGES DEFINITIONS & LOGIC
  final List<AchievementBadge> badges = [
    AchievementBadge(
      id: 'first_step',
      name: 'First Step',
      description: 'Completed your first task',
      icon: Icons.directions_walk,
      color: Colors.blue,
      requirement: 'Complete 1 task',
      isUnlocked: completedCount >= 1,
      progress: (completedCount / 1).clamp(0.0, 1.0),
    ),
    AchievementBadge(
      id: 'quick_responder',
      name: 'Quick Responder',
      description: 'You are always ready to help!',
      icon: Icons.flash_on,
      color: Colors.amber,
      requirement: 'Complete 5 tasks',
      isUnlocked: completedCount >= 5,
      progress: (completedCount / 5).clamp(0.0, 1.0),
    ),
    AchievementBadge(
      id: 'first_aid_pro',
      name: 'First Aid Pro',
      description: 'Master of medical assistance',
      icon: Icons.health_and_safety,
      color: Colors.red,
      requirement: 'Complete 10 medical tasks',
      // For demo: generic count logic or match "medical" in titles if available
      // Using generic count / 2 for demo purposes as "Medical" tasks aren't strictly categorized yet
      isUnlocked: completedCount >= 10, 
      progress: (completedCount / 10).clamp(0.0, 1.0),
    ),
    AchievementBadge(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Helping the community while others sleep',
      icon: Icons.nights_stay,
      color: Colors.deepPurple,
      requirement: 'Submit 5 tasks at night (8PM - 5AM)',
      isUnlocked: nightTasks >= 5,
      progress: (nightTasks / 5).clamp(0.0, 1.0),
    ),
    AchievementBadge(
      id: 'century',
      name: 'Century',
      description: 'A true legend!',
      icon: Icons.emoji_events,
      color: Colors.purple,
      requirement: 'Complete 100 tasks',
      isUnlocked: completedCount >= 100,
      progress: (completedCount / 100).clamp(0.0, 1.0),
    ),
    AchievementBadge(
      id: 'verifier',
      name: 'Verifier',
      description: 'Ensuring quality',
      icon: Icons.verified,
      color: Colors.green,
      requirement: 'Earn 500 points',
      isUnlocked: totalPoints >= 500,
      progress: (totalPoints / 500).clamp(0.0, 1.0),
    ),
  ];

  return badges;
});
