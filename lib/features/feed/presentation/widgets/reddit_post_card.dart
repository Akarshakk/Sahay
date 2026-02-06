import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/models/feed_post_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/post_chat_screen.dart';

class RedditPostCard extends ConsumerWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onVerify; // Additional action for verification
  final bool isDetailed;

  const RedditPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onVerify,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = AppTheme.isDarkMode(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isDetailed
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostChatScreen(post: post),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author, Location, Time
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryBrand.withOpacity(0.1),
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppTheme.primaryBrand,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isPromoted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBrand.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PROMOTED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.primaryBrand,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (post.category.isNotEmpty) ...[
                              Text(
                                post.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('•',
                                  style: TextStyle(
                                      color: AppTheme.getSecondaryTextColor(
                                          context),
                                      fontSize: 10)),
                              const SizedBox(width: 4),
                            ],
                            if (post.address != null) ...[
                              Icon(Icons.location_on,
                                  size: 10,
                                  color:
                                      AppTheme.getSecondaryTextColor(context)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  post.address!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        AppTheme.getSecondaryTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('•',
                                  style: TextStyle(
                                      color: AppTheme.getSecondaryTextColor(
                                          context),
                                      fontSize: 10)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _formatTime(post.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz,
                        color: AppTheme.getSecondaryTextColor(context)),
                    onPressed: () {}, // Options menu
                  ),
                ],
              ),
            ),

            // Content: Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppTheme.getTextColor(context),
                ),
                maxLines: isDetailed ? null : 4,
                overflow: isDetailed ? null : TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Media
            if (post.mediaUrls.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: post.mediaUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: MediaQuery.of(context).size.width - 48,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: post.mediaUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor:
                                isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            highlightColor:
                                isDark ? Colors.grey[700]! : Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.error_outline,
                                    color: Colors.grey)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // Footer: Actions
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Vote and Comments on Left
                  Row(
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.arrow_upward_rounded,
                        label: '${post.likes.length}',
                        onTap: onLike,
                        color: post.likes.isNotEmpty
                            ? AppTheme.primaryBrand
                            : null, // Todo: check if current user liked properly
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.arrow_downward_rounded,
                        onTap: () {}, // Downvote
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        context,
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${post.commentsCount}',
                        onTap: isDetailed
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostChatScreen(post: post),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),

                  // Share and Verify on Right
                  Row(
                    children: [
                      if (onVerify != null)
                        _buildActionButton(
                          context,
                          icon: Icons.verified_outlined,
                          label: 'Verify (${post.verificationCount})',
                          onTap: onVerify,
                          color: AppTheme.primaryGreen,
                        ),
                      _buildActionButton(
                        context,
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: onShare,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      String? label,
      required VoidCallback? onTap,
      Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? AppTheme.getSecondaryTextColor(context),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
