import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/verification_provider.dart';

/// Verification Screen - Volunteer can verify nearby incidents
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<_VerifiablePost> _posts = _getDemoPosts();

  static List<_VerifiablePost> _getDemoPosts() {
    final now = DateTime.now();
    return [
      _VerifiablePost(
        id: 'v1',
        content: '🚨 Major traffic congestion on Ring Road due to vehicle breakdown. Expect 20+ minute delays.',
        category: 'Traffic',
        location: 'Ring Road, Sector 45',
        distance: '0.8 km',
        time: now.subtract(const Duration(minutes: 10)),
        verificationCount: 3,
        requiredVerifications: 5,
      ),
      _VerifiablePost(
        id: 'v2',
        content: '🔥 Small fire at construction site. Fire brigade informed. No injuries reported.',
        category: 'Emergency',
        location: 'Industrial Area, Phase 2',
        distance: '1.2 km',
        time: now.subtract(const Duration(minutes: 25)),
        verificationCount: 4,
        requiredVerifications: 5,
      ),
      _VerifiablePost(
        id: 'v3',
        content: '⚠️ Water pipe burst causing flooding on main street. Municipal team notified.',
        category: 'Infrastructure',
        location: 'Main Market Road',
        distance: '1.5 km',
        time: now.subtract(const Duration(minutes: 40)),
        verificationCount: 2,
        requiredVerifications: 5,
      ),
      _VerifiablePost(
        id: 'v4',
        content: '🌳 Tree fallen blocking lane. Traffic moving slow. Authorities informed.',
        category: 'Hazard',
        location: 'Green Avenue',
        distance: '2.1 km',
        time: now.subtract(const Duration(hours: 1)),
        verificationCount: 1,
        requiredVerifications: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Incidents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.volunteerAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: AppTheme.volunteerAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${verificationState.totalVerificationsToday}',
                  style: const TextStyle(
                    color: AppTheme.volunteerAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return _buildVerificationCard(_posts[index], index, verificationState);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.volunteerAccent.withOpacity(0.3),
            AppTheme.volunteerAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.volunteerAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.volunteerAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Verification Works',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verify incidents near you to help prioritize emergency response. 5 verifications = official alert.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildVerificationCard(_VerifiablePost post, int index, VerificationState state) {
    final hasVerified = ref.read(verificationProvider.notifier).hasUserVerified(post.id);
    final currentCount = state.verifications[post.id]?.count ?? post.verificationCount;
    final progress = currentCount / post.requiredVerifications;
    final isFullyVerified = currentCount >= post.requiredVerifications;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFullyVerified
              ? AppTheme.primaryGreen.withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryBadge(post.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${post.distance} away • ${_formatTime(post.time)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFullyVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ VERIFIED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          // Progress & Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentCount/${post.requiredVerifications} verifications',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: isFullyVerified ? AppTheme.primaryGreen : AppTheme.volunteerAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFullyVerified
                                ? [AppTheme.primaryGreen, const Color(0xFF00E676)]
                                : [AppTheme.volunteerAccent, const Color(0xFF9C88FF)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasVerified || isFullyVerified
                        ? null
                        : () => _verifyPost(post),
                    icon: Icon(
                      hasVerified ? Icons.check : Icons.verified_user,
                    ),
                    label: Text(
                      hasVerified
                          ? 'Already Verified'
                          : isFullyVerified
                              ? 'Fully Verified'
                              : 'Verify This Incident',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasVerified || isFullyVerified
                          ? Colors.white24
                          : AppTheme.volunteerAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    IconData icon;

    switch (category) {
      case 'Traffic':
        color = Colors.orange;
        icon = Icons.traffic;
        break;
      case 'Emergency':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'Infrastructure':
        color = Colors.blue;
        icon = Icons.build;
        break;
      case 'Hazard':
        color = Colors.amber;
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _verifyPost(_VerifiablePost post) {
    final success = ref.read(verificationProvider.notifier).verifyPost(
          post.id,
          currentCount: post.verificationCount,
        );

    if (success) {
      // Update local state
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = _posts[index].copyWith(
            verificationCount: _posts[index].verificationCount + 1,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('✅ Verification recorded! +10 points'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Verifiable post model
class _VerifiablePost {
  final String id;
  final String content;
  final String category;
  final String location;
  final String distance;
  final DateTime time;
  final int verificationCount;
  final int requiredVerifications;

  _VerifiablePost({
    required this.id,
    required this.content,
    required this.category,
    required this.location,
    required this.distance,
    required this.time,
    required this.verificationCount,
    required this.requiredVerifications,
  });

  _VerifiablePost copyWith({
    String? id,
    String? content,
    String? category,
    String? location,
    String? distance,
    DateTime? time,
    int? verificationCount,
    int? requiredVerifications,
  }) {
    return _VerifiablePost(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      verificationCount: verificationCount ?? this.verificationCount,
      requiredVerifications: requiredVerifications ?? this.requiredVerifications,
    );
  }
}
