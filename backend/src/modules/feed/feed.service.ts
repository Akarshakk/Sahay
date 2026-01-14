import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ConfigService } from '@nestjs/config';
import { CommunityPost, CommunityPostDocument } from './schemas/community-post.schema';
import { CreatePostDto, FeedQueryDto, VerifyPostDto } from './dto';
import { IncidentsService } from '../incidents/incidents.service';
import { UsersService } from '../users/users.service';

/**
 * FeedService - Core service for Community Pulse feature
 * 
 * Handles:
 * 1. Creating posts with geolocation
 * 2. Fetching nearby posts (2km radius) using MongoDB geospatial queries
 * 3. Volunteer verification with gamification
 * 4. Auto-promotion to PostgreSQL incidents when threshold reached
 */
@Injectable()
export class FeedService {
  private readonly logger = new Logger(FeedService.name);
  private readonly searchRadiusMeters: number;
  private readonly verificationThreshold: number;

  constructor(
    @InjectModel(CommunityPost.name)
    private readonly communityPostModel: Model<CommunityPostDocument>,
    
    @Inject(forwardRef(() => IncidentsService))
    private readonly incidentsService: IncidentsService,
    
    private readonly usersService: UsersService,
    private readonly configService: ConfigService,
  ) {
    this.searchRadiusMeters = this.configService.get<number>(
      'DEFAULT_SEARCH_RADIUS_METERS',
      2000, // 2km default
    );
    this.verificationThreshold = this.configService.get<number>(
      'VERIFICATION_THRESHOLD',
      5, // 5 verifications to promote
    );

    this.logger.log(`🌍 Feed configured: ${this.searchRadiusMeters}m radius, ${this.verificationThreshold} verifications to promote`);
  }

  /**
   * POST /feed/create - Create a new community post
   * 
   * @param createPostDto - Post content with location
   * @param userId - Author's PostgreSQL user ID
   * @returns Created post document
   */
  async createPost(
    createPostDto: CreatePostDto,
    userId: string,
  ): Promise<CommunityPostDocument> {
    // Get user info for caching author name
    const user = await this.usersService.findById(userId);

    const post = new this.communityPostModel({
      content: createPostDto.content,
      category: createPostDto.category || 'other',
      location: {
        type: 'Point',
        // IMPORTANT: MongoDB uses [longitude, latitude] order!
        coordinates: [createPostDto.longitude, createPostDto.latitude],
      },
      address: createPostDto.address,
      authorId: userId,
      authorName: user.fullName,
      mediaUrls: createPostDto.mediaUrls || [],
      verifications: [],
      verificationCount: 0,
      isPromoted: false,
      isActive: true,
    });

    const savedPost = await post.save();
    
    this.logger.log(
      `📝 Post created: ${savedPost._id} at [${createPostDto.latitude}, ${createPostDto.longitude}]`,
    );

    return savedPost;
  }

  /**
   * GET /feed - Get posts within 2km radius of user's location
   * 
   * CRITICAL: Uses MongoDB's $geoNear aggregation for geospatial queries.
   * The location field must have a 2dsphere index.
   * 
   * @param query - Contains lat, lng, optional radius and pagination
   * @returns Posts within the specified radius, sorted by distance
   */
  async getNearbyFeed(query: FeedQueryDto): Promise<{
    data: CommunityPostDocument[];
    meta: { total: number; radius: number; center: { lat: number; lng: number } };
  }> {
    const {
      latitude,
      longitude,
      radius = this.searchRadiusMeters,
      page = 1,
      limit = 20,
      category,
    } = query;

    this.logger.debug(
      `🔍 Fetching feed: lat=${latitude}, lng=${longitude}, radius=${radius}m`,
    );

    // Build match conditions
    const matchConditions: any = { isActive: true };
    if (category) {
      matchConditions.category = category;
    }

    /**
     * MongoDB Geospatial Query using $geoNear aggregation
     * 
     * $geoNear MUST be the first stage in the pipeline.
     * It uses the 2dsphere index on the 'location' field.
     * 
     * - near: GeoJSON Point of user's location
     * - maxDistance: Maximum distance in METERS (2000m = 2km)
     * - spherical: true for accurate Earth calculations
     * - distanceField: Field to store calculated distance
     */
    const aggregationPipeline: any[] = [
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: [longitude, latitude], // [lng, lat] order!
          },
          distanceField: 'distance', // Will contain distance in meters
          maxDistance: radius, // Maximum distance in meters
          spherical: true, // Use spherical geometry
          query: matchConditions, // Additional filters
        },
      },
      // Sort by distance (closest first), then by recency
      { $sort: { distance: 1, createdAt: -1 } },
      // Pagination
      { $skip: (page - 1) * limit },
      { $limit: limit },
    ];

    // Execute the geospatial query
    const posts = await this.communityPostModel.aggregate(aggregationPipeline);

    // Get total count for pagination
    const countPipeline: any[] = [
      {
        $geoNear: {
          near: { type: 'Point' as const, coordinates: [longitude, latitude] as [number, number] },
          distanceField: 'distance',
          maxDistance: radius,
          spherical: true,
          query: matchConditions,
        },
      },
      { $count: 'total' },
    ];
    
    const countResult = await this.communityPostModel.aggregate(countPipeline);
    const total = countResult[0]?.total || 0;

    this.logger.log(`📍 Found ${posts.length} posts within ${radius}m of [${latitude}, ${longitude}]`);

    return {
      data: posts,
      meta: {
        total,
        radius,
        center: { lat: latitude, lng: longitude },
      },
    };
  }

  /**
   * Alternative method using $geoWithin for strict boundary queries
   * Finds all posts within a circular area (no distance sorting)
   */
  async getPostsWithinRadius(
    latitude: number,
    longitude: number,
    radiusMeters: number = this.searchRadiusMeters,
  ): Promise<CommunityPostDocument[]> {
    // Convert radius from meters to radians for $centerSphere
    // Earth's radius ≈ 6378100 meters
    const radiusInRadians = radiusMeters / 6378100;

    return this.communityPostModel.find({
      isActive: true,
      location: {
        $geoWithin: {
          $centerSphere: [[longitude, latitude], radiusInRadians],
        },
      },
    })
    .sort({ createdAt: -1 })
    .exec();
  }

  /**
   * GET /feed/:id - Get a single post by ID
   */
  async getPostById(postId: string): Promise<CommunityPostDocument> {
    if (!Types.ObjectId.isValid(postId)) {
      throw new BadRequestException('Invalid post ID format');
    }

    const post = await this.communityPostModel.findById(postId);
    
    if (!post || !post.isActive) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    return post;
  }

  /**
   * POST /feed/:id/verify - Volunteer verification endpoint
   * 
   * BUSINESS LOGIC:
   * 1. Only volunteers can verify posts
   * 2. Users cannot verify their own posts
   * 3. Each user can only verify once
   * 4. If verificationCount reaches threshold (5), promote to incident
   * 
   * @param postId - MongoDB ObjectId of the post
   * @param userId - PostgreSQL user ID of the volunteer
   * @returns Updated post document
   */
  async verifyPost(
    postId: string,
    userId: string,
    dto?: VerifyPostDto,
  ): Promise<{ post: CommunityPostDocument; promoted: boolean; incidentId?: string }> {
    // Validate post exists
    const post = await this.getPostById(postId);

    // Check if already promoted
    if (post.isPromoted) {
      throw new BadRequestException('This post has already been promoted to an official incident');
    }

    // Check if user is author (cannot verify own post)
    if (post.authorId === userId) {
      throw new ForbiddenException('You cannot verify your own post');
    }

    // Check if user is a volunteer
    const isVolunteer = await this.usersService.isVolunteer(userId);
    if (!isVolunteer) {
      throw new ForbiddenException('Only volunteers can verify posts');
    }

    // Check if user already verified this post
    const alreadyVerified = post.verifications.some(
      (v) => v.odeclareId === userId,
    );
    if (alreadyVerified) {
      throw new BadRequestException('You have already verified this post');
    }

    // Add verification
    post.verifications.push({
      odeclareId: userId,
      verifiedAt: new Date(),
    });
    post.verificationCount = post.verifications.length;

    await post.save();

    // Update user's verification count (gamification)
    await this.usersService.incrementVerificationCount(userId);

    this.logger.log(
      `✅ Post ${postId} verified by ${userId}. Count: ${post.verificationCount}/${this.verificationThreshold}`,
    );

    // Check if threshold reached - PROMOTE TO INCIDENT
    let promoted = false;
    let incidentId: string | undefined;

    if (post.verificationCount >= this.verificationThreshold && !post.isPromoted) {
      const incident = await this.promoteToIncident(post);
      promoted = true;
      incidentId = incident.id;
    }

    return { post, promoted, incidentId };
  }

  /**
   * PROMOTION LOGIC: Move verified post to PostgreSQL incidents table
   * 
   * This is triggered when a community post receives enough verifications,
   * indicating the community has validated the issue.
   * 
   * @param post - The community post to promote
   * @returns Created incident from PostgreSQL
   */
  private async promoteToIncident(post: CommunityPostDocument) {
    this.logger.log(`🚀 Promoting post ${post._id} to official incident`);

    // Create incident in PostgreSQL
    const incident = await this.incidentsService.createFromCommunityPost({
      title: `Community Report: ${post.category}`,
      description: post.content,
      category: post.category,
      latitude: post.location.coordinates[1], // MongoDB stores [lng, lat]
      longitude: post.location.coordinates[0],
      address: post.address,
      mediaUrls: post.mediaUrls,
      reporterId: post.authorId,
      communityPostId: post._id.toString(),
      verificationCount: post.verificationCount,
    });

    // Update the community post to mark as promoted
    post.isPromoted = true;
    post.promotedIncidentId = incident.id;
    post.promotedAt = new Date();
    await post.save();

    this.logger.log(
      `🎉 Post ${post._id} promoted to incident ${incident.id}`,
    );

    return incident;
  }

  /**
   * Get posts by author
   */
  async getPostsByAuthor(authorId: string): Promise<CommunityPostDocument[]> {
    return this.communityPostModel
      .find({ authorId, isActive: true })
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Soft delete a post (author only)
   */
  async deletePost(postId: string, userId: string): Promise<void> {
    const post = await this.getPostById(postId);

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    post.isActive = false;
    await post.save();

    this.logger.log(`🗑️ Post ${postId} soft-deleted by author ${userId}`);
  }

  /**
   * Get trending posts (most verifications in last 24 hours)
   */
  async getTrendingPosts(
    latitude: number,
    longitude: number,
    limit = 10,
  ): Promise<CommunityPostDocument[]> {
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    return this.communityPostModel.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: [longitude, latitude] },
          distanceField: 'distance',
          maxDistance: this.searchRadiusMeters,
          spherical: true,
          query: {
            isActive: true,
            isPromoted: false,
            createdAt: { $gte: oneDayAgo },
          },
        },
      },
      { $sort: { verificationCount: -1, distance: 1 } },
      { $limit: limit },
    ]);
  }
}
