import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
  ApiParam,
  ApiResponse,
} from '@nestjs/swagger';
import { FeedService } from './feed.service';
import { CreatePostDto, FeedQueryDto, VerifyPostDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

/**
 * FeedController - Community Pulse API
 * 
 * Endpoints:
 * - POST /feed/create - Create a new local post
 * - GET /feed - Get nearby posts (2km radius, geospatial query)
 * - POST /feed/:id/verify - Volunteer verification
 * - GET /feed/:id - Get single post
 * - DELETE /feed/:id - Delete own post
 */
@ApiTags('feed')
@Controller('feed')
export class FeedController {
  constructor(private readonly feedService: FeedService) { }

  /**
   * POST /feed/create
   * Create a new community post with geolocation
   */
  @Post('create')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create a new community post',
    description:
      'Post a local issue with your current location. Other citizens within 2km will see this post.',
  })
  @ApiResponse({ status: 201, description: 'Post created successfully' })
  async createPost(@Request() req: any, @Body() createPostDto: CreatePostDto) {
    const post = await this.feedService.createPost(createPostDto, req.user.id);
    return {
      success: true,
      message: 'Post created successfully',
      data: post,
    };
  }

  /**
   * GET /feed
   * Get nearby posts using geospatial query
   * 
   * CRITICAL: This is the hyper-local feed. Users ONLY see posts
   * within 2km (configurable) of their current location.
   */
  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get nearby community posts',
    description:
      'Returns posts within 2km radius of the specified location. Uses Firestore for data storage.',
  })
  @ApiQuery({ name: 'latitude', required: true, type: Number, example: 28.6139 })
  @ApiQuery({ name: 'longitude', required: true, type: Number, example: 77.209 })
  @ApiQuery({ name: 'radius', required: false, type: Number, description: 'Radius in meters (default: 2000)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false, type: String })
  async getNearbyFeed(@Query() query: FeedQueryDto) {
    return this.feedService.getNearbyFeed(query);
  }

  /**
   * GET /feed/trending
   * Get trending posts (most verified) in the area
   */
  @Get('trending')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get trending posts nearby',
    description: 'Returns most verified posts in the last 24 hours within radius',
  })
  @ApiQuery({ name: 'latitude', required: true, type: Number })
  @ApiQuery({ name: 'longitude', required: true, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getTrendingPosts(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
    @Query('limit') limit?: number,
  ) {
    const posts = await this.feedService.getTrendingPosts(latitude, longitude, limit);
    return {
      success: true,
      data: posts,
    };
  }

  /**
   * GET /feed/my-posts
   * Get current user's posts
   */
  @Get('my-posts')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get my posts' })
  async getMyPosts(@Request() req: any) {
    const posts = await this.feedService.getPostsByAuthor(req.user.id);
    return {
      success: true,
      data: posts,
    };
  }

  /**
   * GET /feed/:id
   * Get a single post by ID
   */
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get post by ID' })
  @ApiParam({ name: 'id', description: 'Firestore document ID of the post' })
  async getPostById(@Param('id') id: string) {
    const post = await this.feedService.getPostById(id);
    return {
      success: true,
      data: post,
    };
  }

  /**
   * POST /feed/:id/verify
   * Volunteer verification endpoint
   * 
   * GAMIFICATION LOGIC:
   * - Only volunteers can verify
   * - Cannot verify own posts
   * - Each user can only verify once
   * - If post reaches 5+ verifications, it's promoted to official incident
   */
  @Post(':id/verify')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Verify a community post (Volunteers only)',
    description:
      'Volunteers can verify posts to validate issues. When a post receives 5+ verifications, it is automatically promoted to an official incident.',
  })
  @ApiParam({ name: 'id', description: 'Firestore document ID of the post to verify' })
  @ApiResponse({
    status: 200,
    description: 'Post verified. If promoted, includes incident ID.',
  })
  @ApiResponse({ status: 403, description: 'Not a volunteer or own post' })
  @ApiResponse({ status: 400, description: 'Already verified or post promoted' })
  async verifyPost(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto?: VerifyPostDto,
  ) {
    const result = await this.feedService.verifyPost(id, req.user.id, dto);

    const response: any = {
      success: true,
      message: result.promoted
        ? '🎉 Post verified and promoted to official incident!'
        : '✅ Post verified successfully',
      data: {
        post: result.post,
        verificationCount: result.post.verificationCount,
        promoted: result.promoted,
      },
    };

    if (result.promoted) {
      response.data.incidentId = result.incidentId;
    }

    return response;
  }

  /**
   * DELETE /feed/:id
   * Soft delete a post (author only)
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete your post' })
  @ApiParam({ name: 'id', description: 'Firestore document ID of the post to delete' })
  async deletePost(@Param('id') id: string, @Request() req: any) {
    await this.feedService.deletePost(id, req.user.id);
    return {
      success: true,
      message: 'Post deleted successfully',
    };
  }
}
