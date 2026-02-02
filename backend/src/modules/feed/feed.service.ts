import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { ConfigService } from '@nestjs/config';
import { FIREBASE_APP } from '../../firebase';
import { CommunityPost } from './feed.interface';
import { CreatePostDto, FeedQueryDto, VerifyPostDto } from './dto';
import { IncidentsService } from '../incidents/incidents.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class FeedService {
  private readonly logger = new Logger(FeedService.name);
  private readonly searchRadiusMeters: number;
  private readonly verificationThreshold: number;
  private db: admin.firestore.Firestore;
  private feedCollection: admin.firestore.CollectionReference;

  constructor(
    @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
    @Inject(forwardRef(() => IncidentsService))
    private readonly incidentsService: IncidentsService,
    private readonly usersService: UsersService,
    private readonly configService: ConfigService,
  ) {
    this.db = admin.firestore(this.firebaseApp);
    this.feedCollection = this.db.collection('feed');
    this.searchRadiusMeters = this.configService.get<number>(
      'DEFAULT_SEARCH_RADIUS_METERS',
      2000,
    );
    this.verificationThreshold = this.configService.get<number>(
      'VERIFICATION_THRESHOLD',
      5,
    );

    this.logger.log(
      `🌍 Feed configured: ${this.searchRadiusMeters}m radius, ${this.verificationThreshold} verifications to promote`,
    );
  }

  /**
   * Helper to serialize a post from Firestore, converting Timestamps to ISO strings
   */
  private serializePost(data: any): CommunityPost {
    return {
      ...data,
      createdAt:
        data.createdAt && typeof data.createdAt.toDate === 'function'
          ? data.createdAt.toDate().toISOString()
          : data.createdAt,
      updatedAt:
        data.updatedAt && typeof data.updatedAt.toDate === 'function'
          ? data.updatedAt.toDate().toISOString()
          : data.updatedAt,
    };
  }

  async createPost(
    createPostDto: CreatePostDto,
    userId: string,
  ): Promise<CommunityPost> {
    const user = await this.usersService.findById(userId);
    const postRef = this.feedCollection.doc();
    const now = new Date();

    const post: CommunityPost = {
      id: postRef.id,
      content: createPostDto.content,
      category: createPostDto.category || 'other',
      location: {
        latitude: createPostDto.latitude,
        longitude: createPostDto.longitude,
      },
      address: createPostDto.address,
      authorId: userId,
      authorName: user.fullName,
      mediaUrls: createPostDto.mediaUrls || [],
      verifications: [],
      verificationCount: 0,
      isPromoted: false,
      isActive: true,
      likes: [],
      commentsCount: 0,
      createdAt: now,
      updatedAt: now,
    };

    await postRef.set(post);
    this.logger.log(
      `📝 Post created: ${post.id} at [${createPostDto.latitude}, ${createPostDto.longitude}]`,
    );

    return post;
  }

  async getNearbyFeed(query: FeedQueryDto): Promise<{
    data: CommunityPost[];
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

    // Simple bounding box calculation
    const latDelta = radius / 111320;
    const lngDelta = radius / (111320 * Math.cos(latitude * (Math.PI / 180)));

    // COMPLETELY SIMPLIFIED QUERY: Only filter by Latitude Range.
    // This effectively uses a Single-Field Index which is auto-created by Firestore.
    // We will filter 'isActive' and 'longitude' in memory.
    let firestoreQuery: admin.firestore.Query = this.feedCollection
      .where('location.latitude', '>=', latitude - latDelta)
      .where('location.latitude', '<=', latitude + latDelta)
      .orderBy('location.latitude');

    const snapshot = await firestoreQuery.get();
    this.logger.log(`🔍 Raw Firestore results: ${snapshot.docs.length} docs`);

    // Filter by longitude and category in memory, AND sort by createdAt descending
    let posts = snapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          ...data,
          // Firestore Timestamps need conversion to Date objects
          createdAt:
            data.createdAt && typeof data.createdAt.toDate === 'function'
              ? data.createdAt.toDate()
              : new Date(data.createdAt),
          updatedAt:
            data.updatedAt && typeof data.updatedAt.toDate === 'function'
              ? data.updatedAt.toDate()
              : new Date(data.updatedAt),
          id: doc.id,
        } as CommunityPost;
      })
      .filter(
        (post) => {
          const isActive = post.isActive === true;
          const isValid = post.location.longitude >= longitude - lngDelta &&
            post.location.longitude <= longitude + lngDelta;

          if (!isActive) this.logger.debug(`❌ Post ${post.id} filtered: inactive`);
          if (!isValid) this.logger.debug(`❌ Post ${post.id} filtered: lng out of bounds`);

          return isActive && isValid;
        }
      );

    if (category) {
      posts = posts.filter((post) => post.category === category);
    }

    // Reddit-style Engagement Ranking Algorithm
    // Score = (verifications * 3) + (likes * 2) + (comments * 1)
    // Higher engagement = higher priority, tie-breaker = newest first
    const getEngagementScore = (post: CommunityPost): number => {
      const verifications = post.verificationCount || 0;
      const likes = post.likes?.length || 0;
      const comments = post.commentsCount || 0;
      return (verifications * 3) + (likes * 2) + (comments * 1);
    };

    posts.sort((a, b) => {
      const scoreA = getEngagementScore(a);
      const scoreB = getEngagementScore(b);

      // Primary sort: engagement score (descending)
      if (scoreB !== scoreA) {
        return scoreB - scoreA;
      }

      // Tie-breaker: newest first
      return b.createdAt.getTime() - a.createdAt.getTime();
    });

    const total = posts.length;

    // Paginate
    const startIndex = (page - 1) * limit;
    const paginatedPosts = posts.slice(startIndex, startIndex + limit);

    this.logger.log(
      `📍 Found ${posts.length} posts (returning ${paginatedPosts.length}) within ${radius}m`,
    );

    return {
      data: paginatedPosts,
      meta: {
        total,
        radius,
        center: { lat: latitude, lng: longitude },
      },
    };
  }

  async getPostsWithinRadius(
    latitude: number,
    longitude: number,
    radiusMeters: number = this.searchRadiusMeters,
  ): Promise<CommunityPost[]> {
    const latDelta = radiusMeters / 111320;
    const lngDelta = radiusMeters / (111320 * Math.cos(latitude * (Math.PI / 180)));

    const snapshot = await this.feedCollection
      .where('isActive', '==', true)
      .where('location.latitude', '>=', latitude - latDelta)
      .where('location.latitude', '<=', latitude + latDelta)
      .orderBy('location.latitude')
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs
      .map((doc) => doc.data() as CommunityPost)
      .filter(
        (post) =>
          post.location.longitude >= longitude - lngDelta &&
          post.location.longitude <= longitude + lngDelta,
      );
  }

  async getPostById(postId: string): Promise<CommunityPost> {
    const doc = await this.feedCollection.doc(postId).get();

    if (!doc.exists) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    const post = doc.data() as CommunityPost;
    if (!post.isActive) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    return post;
  }

  async verifyPost(
    postId: string,
    userId: string,
    dto?: VerifyPostDto,
  ): Promise<{ post: CommunityPost; promoted: boolean; incidentId?: string }> {
    const post = await this.getPostById(postId);

    if (post.isPromoted) {
      throw new BadRequestException(
        'This post has already been promoted to an official incident',
      );
    }

    if (post.authorId === userId) {
      throw new ForbiddenException('You cannot verify your own post');
    }

    const isVolunteer = await this.usersService.isVolunteer(userId);
    if (!isVolunteer) {
      throw new ForbiddenException('Only volunteers can verify posts');
    }

    const alreadyVerified = post.verifications.some((v) => v.odeclareId === userId);
    if (alreadyVerified) {
      throw new BadRequestException('You have already verified this post');
    }

    // Update post
    post.verifications.push({
      odeclareId: userId,
      verifiedAt: new Date(),
    });
    post.verificationCount = post.verifications.length;
    post.updatedAt = new Date();

    await this.feedCollection.doc(postId).update({
      verifications: post.verifications,
      verificationCount: post.verificationCount,
      updatedAt: post.updatedAt,
    });

    await this.usersService.incrementVerificationCount(userId);

    this.logger.log(
      `✅ Post ${postId} verified by ${userId}. Count: ${post.verificationCount}/${this.verificationThreshold}`,
    );

    let promoted = false;
    let incidentId: string | undefined;

    if (post.verificationCount >= this.verificationThreshold && !post.isPromoted) {
      const incident = await this.promoteToIncident(post);
      promoted = true;
      incidentId = incident.id;
    }

    return { post, promoted, incidentId };
  }

  private async promoteToIncident(post: CommunityPost) {
    this.logger.log(`🚀 Promoting post ${post.id} to official incident`);

    const incident = await this.incidentsService.createFromCommunityPost({
      title: `Community Report: ${post.category}`,
      description: post.content,
      category: post.category,
      latitude: post.location.latitude,
      longitude: post.location.longitude,
      address: post.address,
      mediaUrls: post.mediaUrls,
      reporterId: post.authorId,
      communityPostId: post.id,
      verificationCount: post.verificationCount,
    });

    await this.feedCollection.doc(post.id).update({
      isPromoted: true,
      promotedIncidentId: incident.id,
      promotedAt: new Date(),
      updatedAt: new Date(),
    });

    this.logger.log(`🎉 Post ${post.id} promoted to incident ${incident.id}`);

    return incident;
  }

  async getPostsByAuthor(authorId: string): Promise<CommunityPost[]> {
    const snapshot = await this.feedCollection
      .where('authorId', '==', authorId)
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs.map((doc) => doc.data() as CommunityPost);
  }

  async deletePost(postId: string, userId: string): Promise<void> {
    const post = await this.getPostById(postId);

    if (post.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    await this.feedCollection.doc(postId).update({
      isActive: false,
      updatedAt: new Date(),
    });

    this.logger.log(`🗑️ Post ${postId} soft-deleted by author ${userId}`);
  }

  async getTrendingPosts(
    latitude: number,
    longitude: number,
    limit = 10,
  ): Promise<CommunityPost[]> {
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const latDelta = this.searchRadiusMeters / 111320;
    const lngDelta = this.searchRadiusMeters / (111320 * Math.cos(latitude * (Math.PI / 180)));

    const snapshot = await this.feedCollection
      .where('isActive', '==', true)
      .where('isPromoted', '==', false)
      .where('createdAt', '>=', oneDayAgo)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs
      .map((doc) => doc.data() as CommunityPost)
      .filter(
        (post) =>
          post.location.latitude >= latitude - latDelta &&
          post.location.latitude <= latitude + latDelta &&
          post.location.longitude >= longitude - lngDelta &&
          post.location.longitude <= longitude + lngDelta,
      )
      .sort((a, b) => b.verificationCount - a.verificationCount)
      .slice(0, limit);
  }

  async addComment(
    postId: string,
    userId: string,
    content: string,
  ): Promise<CommunityPost> {
    const user = await this.usersService.findById(userId);
    const postRef = this.feedCollection.doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    const commentRef = postRef.collection('comments').doc();
    const now = new Date();

    const comment = {
      id: commentRef.id,
      postId,
      authorId: userId,
      authorName: user.fullName,
      message: content,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };

    await commentRef.set(comment);

    // Update post comment count
    await postRef.update({
      commentsCount: admin.firestore.FieldValue.increment(1),
    });

    return this.serializePost((await postRef.get()).data());
  }

  async getComments(postId: string): Promise<any[]> {
    const commentsRef = this.feedCollection.doc(postId).collection('comments');
    const snapshot = await commentsRef.orderBy('createdAt', 'asc').get();
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        ...data,
        id: doc.id,
        createdAt:
          data.createdAt && typeof data.createdAt.toDate === 'function'
            ? data.createdAt.toDate().toISOString()
            : data.createdAt,
      };
    });
  }

  async toggleLike(postId: string, userId: string): Promise<CommunityPost> {
    const postRef = this.feedCollection.doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new NotFoundException(`Post with ID ${postId} not found`);
    }

    const post = postDoc.data() as CommunityPost;
    const likes = post.likes || [];
    const index = likes.indexOf(userId);

    if (index === -1) {
      // Like
      await postRef.update({
        likes: admin.firestore.FieldValue.arrayUnion(userId),
      });
    } else {
      // Unlike
      await postRef.update({
        likes: admin.firestore.FieldValue.arrayRemove(userId),
      });
    }

    return this.serializePost((await postRef.get()).data());
  }
}
