import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_post_model.dart';

/// Verification data for a post
class VerificationData {
  final String postId;
  final int count;
  final bool isVerifiedByUser;
  final DateTime? verifiedAt;

  VerificationData({
    required this.postId,
    required this.count,
    this.isVerifiedByUser = false,
    this.verifiedAt,
  });

  VerificationData copyWith({
    String? postId,
    int? count,
    bool? isVerifiedByUser,
    DateTime? verifiedAt,
  }) {
    return VerificationData(
      postId: postId ?? this.postId,
      count: count ?? this.count,
      isVerifiedByUser: isVerifiedByUser ?? this.isVerifiedByUser,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

/// Global verification state that syncs across all roles
class VerificationState {
  final Map<String, VerificationData> verifications;
  final int totalVerificationsToday;
  final int volunteerPoints;

  VerificationState({
    this.verifications = const {},
    this.totalVerificationsToday = 0,
    this.volunteerPoints = 0,
  });

  VerificationState copyWith({
    Map<String, VerificationData>? verifications,
    int? totalVerificationsToday,
    int? volunteerPoints,
  }) {
    return VerificationState(
      verifications: verifications ?? this.verifications,
      totalVerificationsToday: totalVerificationsToday ?? this.totalVerificationsToday,
      volunteerPoints: volunteerPoints ?? this.volunteerPoints,
    );
  }
}

/// Verification notifier - manages all verification state
class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier() : super(VerificationState());

  /// Verify a post - returns true if successful
  bool verifyPost(String postId, {int currentCount = 0}) {
    final existing = state.verifications[postId];
    
    if (existing?.isVerifiedByUser == true) {
      return false; // Already verified by this user
    }

    final newCount = currentCount + 1;
    final newVerifications = Map<String, VerificationData>.from(state.verifications);
    
    newVerifications[postId] = VerificationData(
      postId: postId,
      count: newCount,
      isVerifiedByUser: true,
      verifiedAt: DateTime.now(),
    );

    state = state.copyWith(
      verifications: newVerifications,
      totalVerificationsToday: state.totalVerificationsToday + 1,
      volunteerPoints: state.volunteerPoints + 10,
    );

    return true;
  }

  /// Get verification count for a post
  int getVerificationCount(String postId, {int fallback = 0}) {
    return state.verifications[postId]?.count ?? fallback;
  }

  /// Check if user verified a post
  bool hasUserVerified(String postId) {
    return state.verifications[postId]?.isVerifiedByUser ?? false;
  }

  /// Reset daily stats (for testing)
  void resetDailyStats() {
    state = state.copyWith(
      totalVerificationsToday: 0,
    );
  }
}

/// Global verification provider
final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});

/// Convenience provider for getting verification count
final verificationCountProvider = Provider.family<int, String>((ref, postId) {
  final state = ref.watch(verificationProvider);
  return state.verifications[postId]?.count ?? 0;
});

/// Check if user verified a specific post
final hasVerifiedProvider = Provider.family<bool, String>((ref, postId) {
  final state = ref.watch(verificationProvider);
  return state.verifications[postId]?.isVerifiedByUser ?? false;
});
