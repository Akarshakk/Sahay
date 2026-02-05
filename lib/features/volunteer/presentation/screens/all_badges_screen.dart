import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/badge_provider.dart';
import '../../../../core/models/badge_model.dart';

class AllBadgesScreen extends ConsumerWidget {
  const AllBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (badges) {
          // Sort unlocked first
          final sortedBadges = List<AchievementBadge>.from(badges)
            ..sort((a, b) {
              if (a.isUnlocked && !b.isUnlocked) return -1;
              if (!a.isUnlocked && b.isUnlocked) return 1;
              return 0;
            });

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, // Cards won't be wider than 200px
              childAspectRatio: 0.8, // Slightly taller cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sortedBadges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(context, sortedBadges[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, AchievementBadge badge, int index) {
    final isUnlocked = badge.isUnlocked;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        decoration: BoxDecoration(
          // Gradient for unlocked, solid/grey for locked
          gradient: isUnlocked 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    badge.color.withOpacity(0.05),
                  ],
                )
              : null,
          color: isUnlocked ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isUnlocked ? 0.08 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUnlocked ? badge.color.withOpacity(0.3) : Colors.grey[200]!,
            width: isUnlocked ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Background decoration icon (faded)
            if (isUnlocked)
              Positioned(
                right: -10,
                bottom: -10,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    badge.icon,
                    size: 80,
                    color: badge.color.withOpacity(0.05),
                  ),
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Ring
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnlocked 
                          ? badge.color.withOpacity(0.1) 
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked ? [
                        BoxShadow(
                          color: badge.color.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Icon(
                      badge.icon,
                      size: 32,
                      color: isUnlocked ? badge.color : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Text Content
                  Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? AppTheme.textDark : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    isUnlocked ? 'Completed' : 'Locked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? badge.color : Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Progress
                  if (!isUnlocked) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: badge.progress,
                        backgroundColor: Colors.grey[200],
                        color: badge.color.withOpacity(0.5),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(badge.progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            
            // Lock Icon Overlay
            if (!isUnlocked)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.lock_outline, size: 16, color: Colors.grey[300]),
              ),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().scale(),
    );
  }

  void _showBadgeDetails(BuildContext context, AchievementBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.icon,
              size: 60,
              color: badge.isUnlocked ? badge.color : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Requirement',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.requirement,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
