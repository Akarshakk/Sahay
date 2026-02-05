import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/verification_provider.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/providers/badge_provider.dart';
import '../../../../core/models/badge_model.dart';
import '../../../../core/models/task_model.dart';
import 'volunteer_tasks_detailed_screen.dart';
import '../../../feed/presentation/screens/community_feed_screen.dart';
import 'all_activities_screen.dart';
import 'all_badges_screen.dart';

/// Volunteer Dashboard - Light Theme UI with stats and quick actions
class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  ConsumerState<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends ConsumerState<VolunteerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);
    // Watch region-based tasks for dynamic count
    final regionTasksAsync = ref.watch(getTasksByRegionProvider('general'));
    final submissionsAsync = ref.watch(getMySubmissionsProvider);
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroStats(verificationState, submissionsAsync, regionTasksAsync),
                  const SizedBox(height: 24),
                  _buildQuickActions(regionTasksAsync),
                  const SizedBox(height: 24),
                  _buildLevelProgress(verificationState),
                  const SizedBox(height: 24),
                  _buildRecentActivity(submissionsAsync),
                  const SizedBox(height: 24),
                  _buildAchievements(badgesAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.volunteerAccent,
                AppTheme.volunteerAccent.withOpacity(0.7),
                AppTheme.primaryGreen,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volunteer Portal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Making a difference, one task at a time',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStats(
      VerificationState state,
      AsyncValue<List<TaskSubmission>> submissionsAsync,
      AsyncValue<List<Task>> regionTasksAsync) {
    // Calculate streak
    final streak = submissionsAsync.when(
      data: (submissions) {
        if (submissions.isEmpty) return 0;
        final verified = submissions.where((s) => s.status == 'verified').toList();
        if (verified.isEmpty) return 0;

        final uniqueDates = verified.map((s) {
          final d = s.createdAt;
          return '${d.year}-${d.month}-${d.day}';
        }).toSet();

        int currentStreak = 0;
        final now = DateTime.now();
        var checkDate = DateTime(now.year, now.month, now.day);
        String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

        // Check today
        if (uniqueDates.contains(dateKey(checkDate))) {
          currentStreak++;
        }
        
        // Move to yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));

        // If today missed, check yesterday to see if streak is alive
        if (currentStreak == 0 && !uniqueDates.contains(dateKey(checkDate))) {
          return 0;
        }

        while (uniqueDates.contains(dateKey(checkDate))) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
        return currentStreak;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Calculate Points
    final points = submissionsAsync.when(
      data: (submissions) {
         return regionTasksAsync.when(
           data: (tasks) {
             int total = 0;
             for (var sub in submissions) {
               if (sub.status == 'verified') {
                 final task = tasks.firstWhere(
                   (t) => t.id == sub.taskId,
                   orElse: () => Task(
                     id: '',
                     title: '',
                     description: '',
                     region: '',
                     areaId: '',
                     createdBy: '',
                     createdAt: DateTime.now(),
                     updatedAt: DateTime.now(),
                     rewardPoints: 0, 
                     assignedTo: [],
                     priority: 'medium',
                     status: '',
                   ), // Empty fallback
                 );
                 total += task.rewardPoints;
               }
             }
             // Add local verification points too?
             // defined in verificationProvider: volunteerPoints tracks "post verifications"
             // Ideally we sum both task points + post verification points
             return total + state.volunteerPoints; 
           },
           loading: () => state.volunteerPoints,
           error: (_, __) => state.volunteerPoints,
         );
      },
      loading: () => state.volunteerPoints,
      error: (_, __) => state.volunteerPoints,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.verified,
                value: state.totalVerificationsToday.toString(),
                label: 'Today',
                color: AppTheme.primaryGreen,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                icon: Icons.star,
                value: '$points',
                label: 'Points',
                color: AppTheme.primaryOrange,
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                icon: Icons.trending_up,
                value: '$streak',
                label: 'Streak',
                color: AppTheme.volunteerAccent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[800], // Darker text for better visibility
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildQuickActions(AsyncValue<List> regionTasksAsync) {
    // Get pending task count from API
    final pendingCount = regionTasksAsync.when(
      data: (tasks) => tasks.where((t) => t.status == 'open').length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.verified_user,
                label: 'Verify Posts',
                subtitle: 'Help verify incidents',
                gradient: [AppTheme.primaryGreen, const Color(0xFF00C853)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityFeedScreen(canVerify: true)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.task_alt,
                label: 'My Tasks',
                subtitle: '$pendingCount open tasks',
                gradient: [AppTheme.volunteerAccent, const Color(0xFF7B68EE)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VolunteerTasksDetailedScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(VerificationState state) {
    final points = state.volunteerPoints;
    final level = (points / 100).floor() + 1;
    final progress = (points % 100) / 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.volunteerAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${points % 100}/100 XP',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.volunteerAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.volunteerAccent, Color(0xFF9C88FF)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${100 - (points % 100)} points to Level ${level + 1}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentActivity(AsyncValue<List<TaskSubmission>> submissionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllActivitiesScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        submissionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading activity: $e'),
          data: (submissions) {
            if (submissions.isEmpty) {
              return const Text('No recent activity yet.');
            }
            // Take top 3
            final recent = submissions.take(3).toList();
            return Column(
              children: recent.map((s) => _buildActivityItem(s)).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildActivityItem(TaskSubmission submission) {
    Color color;
    IconData icon;
    String text;

    switch (submission.status.toLowerCase()) {
      case 'verified':
        color = AppTheme.primaryGreen;
        icon = Icons.verified;
        text = 'Verified Task';
        break;
      case 'rejected':
        color = AppTheme.primaryRed;
        icon = Icons.cancel;
        text = 'Task Rejected';
        break;
      default:
        color = AppTheme.volunteerAccent;
        icon = Icons.timer;
        text = 'Task Submitted';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(submission.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(AsyncValue<List<AchievementBadge>> badgesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllBadgesScreen()),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        badgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error loading badges: $e'),
          data: (badges) {
            // Filter to show only unlocked first, or maybe just list them
            // Let's show a mix, but prioritize interesting ones.
            // Or just show the first 5 defined in provider.
            // Smoothing: Unlocked first
            final sortedBadges = List<AchievementBadge>.from(badges)
              ..sort((a, b) {
                if (a.isUnlocked && !b.isUnlocked) return -1;
                if (!a.isUnlocked && b.isUnlocked) return 1;
                return 0;
              });

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedBadges.map((b) => _buildAchievementBadge(b)).toList(),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildAchievementBadge(AchievementBadge badge) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.isUnlocked ? badge.color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isUnlocked ? badge.color.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            badge.icon,
            color: badge.isUnlocked ? badge.color : Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: badge.isUnlocked ? AppTheme.textDark : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
