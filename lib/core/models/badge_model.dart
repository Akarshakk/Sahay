import 'package:flutter/material.dart';

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String requirement;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.isUnlocked,
    required this.progress,
  });

  AchievementBadge copyWith({
    bool? isUnlocked,
    double? progress,
  }) {
    return AchievementBadge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      color: color,
      requirement: requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
    );
  }
}
