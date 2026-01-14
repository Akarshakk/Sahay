// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedPostImpl _$$FeedPostImplFromJson(Map<String, dynamic> json) =>
    _$FeedPostImpl(
      id: json['_id'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      location: FeedLocation.fromJson(json['location'] as Map<String, dynamic>),
      address: json['address'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      verificationCount: (json['verificationCount'] as num?)?.toInt() ?? 0,
      isPromoted: json['isPromoted'] as bool? ?? false,
      promotedIncidentId: json['promotedIncidentId'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FeedPostImplToJson(_$FeedPostImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'content': instance.content,
      'category': instance.category,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'location': instance.location,
      'address': instance.address,
      'mediaUrls': instance.mediaUrls,
      'verificationCount': instance.verificationCount,
      'isPromoted': instance.isPromoted,
      'promotedIncidentId': instance.promotedIncidentId,
      'distance': instance.distance,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$FeedLocationImpl _$$FeedLocationImplFromJson(Map<String, dynamic> json) =>
    _$FeedLocationImpl(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$$FeedLocationImplToJson(_$FeedLocationImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['_id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      message: json['message'] as String,
      replyToMessageId: json['replyToMessageId'] as String?,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'postId': instance.postId,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'message': instance.message,
      'replyToMessageId': instance.replyToMessageId,
      'reactions': instance.reactions,
      'createdAt': instance.createdAt.toIso8601String(),
    };
