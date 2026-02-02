import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/feed_post_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/verification_provider.dart';
import 'post_chat_screen.dart';
import 'create_post_screen.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  /// When true, shows verify button on posts (for volunteers/authorities)
  final bool canVerify;
  
  const CommunityFeedScreen({super.key, this.canVerify = false});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  List<FeedPost> _posts = [];
  bool _isLoading = true;
  Position? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _loadLocation();
    _setupWebSocket();
  }

  Future<void> _loadLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentPosition = Position(
            latitude: 28.6139,
            longitude: 77.2090,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        _loadFeed();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Use default location
        setState(() {
          _currentPosition = Position(
            latitude: 28.6139,
            longitude: 77.2090,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        _loadFeed();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      _loadFeed();
    } catch (e) {
      // Use default location
      setState(() {
        _currentPosition = Position(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
      _loadFeed();
    }
  }

  void _setupWebSocket() {
    final ws = ref.read(webSocketServiceProvider);
    
    ws.onNewPost((data) {
      setState(() {
        if (data['data'] != null) {
          _posts.insert(0, FeedPost.fromJson(data['data']));
        }
      });
    });

    ws.onPostVerified((data) {
      setState(() {
        int index = _posts.indexWhere((p) => p.id == data['postId']);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(
            verificationCount: data['verificationCount'] ?? post.verificationCount,
            isPromoted: data['promoted'] ?? post.isPromoted,
          );
        }
      });
    });
  }

  Future<void> _loadFeed() async {
    if (_currentPosition == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getNearbyFeed(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10000,
        limit: 50,
      );

      // Backend returns { data: [...], meta: {...} } without a 'success' wrapper
      if (result['data'] != null) {
        setState(() {
          _posts = (result['data'] as List)
              .map((json) => FeedPost.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading feed: $e');
      setState(() {
        _posts = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load feed. Please check connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Demo feed posts for offline mode
  List<FeedPost> _getDemoFeedPosts() {
    final now = DateTime.now();
    return [
      FeedPost(
        id: 'demo-1',
        content: '🚨 Heavy traffic jam on Western Express Highway near Andheri flyover. Expect 30+ min delays. Suggest taking alternate routes via Link Road.',
        category: 'traffic',
        location: const FeedLocation(latitude: 19.1136, longitude: 72.8697),
        address: 'Andheri West, Mumbai',
        authorName: 'Traffic Updates',
        authorId: 'system',
        createdAt: now.subtract(const Duration(minutes: 15)),
        verificationCount: 24,
      ),
      FeedPost(
        id: 'demo-2',
        content: '⚠️ Water supply disruption in Bandra East area. BMC maintenance work in progress. Expected restoration by 6 PM.',
        category: 'infrastructure',
        location: const FeedLocation(latitude: 19.0596, longitude: 72.8295),
        address: 'Bandra East, Mumbai',
        authorName: 'Community Helper',
        authorId: 'volunteer-1',
        createdAt: now.subtract(const Duration(hours: 2)),
        verificationCount: 18,
      ),
      FeedPost(
        id: 'demo-3',
        content: '🔥 Small fire reported near Kurla station. Fire brigade on site. Area being evacuated as precaution. Avoid the area.',
        category: 'emergency',
        location: const FeedLocation(latitude: 19.0728, longitude: 72.8826),
        address: 'Kurla West, Mumbai',
        authorName: 'Emergency Alert',
        authorId: 'authority-1',
        createdAt: now.subtract(const Duration(minutes: 45)),
        verificationCount: 32,
      ),
      FeedPost(
        id: 'demo-4',
        content: '☔ Heavy rainfall expected tonight. IMD issues orange alert for Mumbai. Citizens advised to avoid waterlogged areas.',
        category: 'weather',
        location: const FeedLocation(latitude: 19.0760, longitude: 72.8777),
        address: 'Mumbai, Maharashtra',
        authorName: 'Weather Updates',
        authorId: 'system',
        createdAt: now.subtract(const Duration(hours: 1)),
        verificationCount: 56,
      ),
      FeedPost(
        id: 'demo-5',
        content: '✅ Road repair work completed on SV Road near Malad. Traffic now flowing normally. Thank you for your patience!',
        category: 'infrastructure',
        location: const FeedLocation(latitude: 19.1858, longitude: 72.8483),
        address: 'Malad West, Mumbai',
        authorName: 'BMC Updates',
        authorId: 'authority-2',
        createdAt: now.subtract(const Duration(hours: 3)),
        verificationCount: 12,
      ),
    ];
  }

  Future<void> _toggleLike(FeedPost post) async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.toggleLike(post.id);
      
      if (result['success'] == true && result['data'] != null) {
        final updatedPost = FeedPost.fromJson(result['data']);
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _verifyPost(FeedPost post) async {
    // Check if already verified by user
    if (ref.read(verificationProvider.notifier).hasUserVerified(post.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already verified this post'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.verifyPost(post.id);
      
      if (result['success'] == true) {
        // Update shared verification state
        ref.read(verificationProvider.notifier).verifyPost(
          post.id,
          currentCount: post.verificationCount,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['promoted'] == true 
              ? '🎉 Post promoted to official incident! +10 points' 
              : '✅ Post verified! +10 points'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadFeed();
      }
    } catch (e) {
      // Offline mode - update shared state anyway
      final success = ref.read(verificationProvider.notifier).verifyPost(
        post.id,
        currentCount: post.verificationCount,
      );
      
      if (success) {
        // Update local post count
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(
              verificationCount: _posts[index].verificationCount + 1,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verified! Will sync when online. +10 points'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Community Pulse', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutralGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: _posts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(_posts[index])
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50))
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen(currentPosition: _currentPosition)),
          );
          if (result == true) _loadFeed();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No posts in your area',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to report something!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(FeedPost post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostChatScreen(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryRed,
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildCategoryChip(post.category),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                post.content,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              
              if (post.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.address!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (post.distance != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${(post.distance! / 1000).toStringAsFixed(1)} km away',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              const SizedBox(height: 12),
              
              // Actions
              Row(
                children: [
                  // Verify button - only shown for volunteers/authorities
                  if (widget.canVerify) ...[
                    TextButton.icon(
                      onPressed: () => _verifyPost(post),
                      icon: Icon(
                        Icons.verified,
                        size: 20,
                        color: post.verificationCount >= 5 ? AppTheme.primaryGreen : Colors.grey,
                      ),
                      label: Text(
                        'Verify (${post.verificationCount})',
                        style: TextStyle(
                          color: post.verificationCount >= 5 ? AppTheme.primaryGreen : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Verification badge (always shown, read-only for citizens)
                  if (!widget.canVerify) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: post.verificationCount >= 5 ? AppTheme.primaryGreen : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.verificationCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: post.verificationCount >= 5 ? AppTheme.primaryGreen : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                  ],
                  TextButton.icon(
                    onPressed: () => _toggleLike(post),
                    icon: Icon(
                      post.likes.contains(ref.watch(authControllerProvider)?.id) ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: post.likes.contains(ref.watch(authControllerProvider)?.id) ? Colors.red : Colors.grey,
                    ),
                    label: Text(
                      '${post.likes.length}',
                      style: TextStyle(
                        color: post.likes.contains(ref.watch(authControllerProvider)?.id) ? Colors.red : Colors.grey[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostChatScreen(post: post),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text('${post.commentsCount} Comments'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    IconData icon;
    
    switch (category) {
      case 'infrastructure':
        color = Colors.orange;
        icon = Icons.construction;
        break;
      case 'safety':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'health':
        color = Colors.blue;
        icon = Icons.local_hospital;
        break;
      case 'environment':
        color = Colors.green;
        icon = Icons.eco;
        break;
      case 'accident':
        color = Colors.deepOrange;
        icon = Icons.car_crash;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return DateFormat('MMM d, yyyy').format(timestamp);
  }
}
