import {
  IsString,
  IsNumber,
  IsOptional,
  IsEnum,
  IsArray,
  Min,
  Max,
  MinLength,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';

export enum PostCategory {
  INFRASTRUCTURE = 'infrastructure',
  SAFETY = 'safety',
  SANITATION = 'sanitation',
  TRAFFIC = 'traffic',
  ENVIRONMENT = 'environment',
  OTHER = 'other',
}

/**
 * DTO for creating a new community post
 */
export class CreatePostDto {
  @ApiProperty({
    example: 'Broken streetlight at the corner, very dark at night',
    description: 'Content of the post (1-1000 characters)',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  content: string;

  @ApiPropertyOptional({
    enum: PostCategory,
    example: 'infrastructure',
    description: 'Category of the issue',
  })
  @IsOptional()
  @IsEnum(PostCategory)
  category?: PostCategory;

  @ApiProperty({
    example: 28.6139,
    description: 'Latitude of the issue location',
  })
  @IsNumber()
  @Min(-90)
  @Max(90)
  @Transform(({ value }) => parseFloat(value))
  latitude: number;

  @ApiProperty({
    example: 77.209,
    description: 'Longitude of the issue location',
  })
  @IsNumber()
  @Min(-180)
  @Max(180)
  @Transform(({ value }) => parseFloat(value))
  longitude: number;

  @ApiPropertyOptional({
    example: 'Corner of MG Road and Park Street',
    description: 'Human-readable address',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;

  @ApiPropertyOptional({
    example: ['https://example.com/photo1.jpg'],
    description: 'Array of media URLs (photos/videos)',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaUrls?: string[];
}

/**
 * DTO for querying the nearby feed
 */
export class FeedQueryDto {
  @ApiProperty({
    example: 28.6139,
    description: 'User current latitude',
  })
  @IsNumber()
  @Min(-90)
  @Max(90)
  @Transform(({ value }) => parseFloat(value))
  latitude: number;

  @ApiProperty({
    example: 77.209,
    description: 'User current longitude',
  })
  @IsNumber()
  @Min(-180)
  @Max(180)
  @Transform(({ value }) => parseFloat(value))
  longitude: number;

  @ApiPropertyOptional({
    example: 2000,
    description: 'Search radius in meters (default: 2000m = 2km)',
  })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(10000) // Max 10km
  @Transform(({ value }) => parseInt(value))
  radius?: number;

  @ApiPropertyOptional({
    example: 1,
    description: 'Page number for pagination',
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Transform(({ value }) => parseInt(value))
  page?: number;

  @ApiPropertyOptional({
    example: 20,
    description: 'Number of posts per page',
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(100)
  @Transform(({ value }) => parseInt(value))
  limit?: number;

  @ApiPropertyOptional({
    enum: PostCategory,
    description: 'Filter by category',
  })
  @IsOptional()
  @IsEnum(PostCategory)
  category?: PostCategory;
}

/**
 * DTO for verifying a post (optional comment)
 */
export class VerifyPostDto {
  @ApiPropertyOptional({
    example: 'Confirmed, I saw this issue yesterday',
    description: 'Optional comment when verifying',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
