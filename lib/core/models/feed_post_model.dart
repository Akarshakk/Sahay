import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_post_model.freezed.dart';
part 'feed_post_model.g.dart';

@freezed
class FeedPost with _$FeedPost {
  const factory FeedPost({
    required String id,
    required String content,
    required String category,
    required String authorId,
    required String authorName,
    required FeedLocation location,
    String? address,
    @Default([]) List<String> mediaUrls,
    @Default(0) int verificationCount,
    @Default([]) List<String> likes,
    @Default(0) int commentsCount,
    required DateTime createdAt,
    @Default(false) bool isPromoted,
    double? distance,
    DateTime? updatedAt,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) => _$FeedPostFromJson(json);
}

@freezed
class FeedLocation with _$FeedLocation {
  const factory FeedLocation({
    required double latitude,
    required double longitude,
  }) = _FeedLocation;

  factory FeedLocation.fromJson(Map<String, dynamic> json) => _$FeedLocationFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String message,
    String? replyToMessageId,
    @Default([]) List<String> reactions,
    required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
