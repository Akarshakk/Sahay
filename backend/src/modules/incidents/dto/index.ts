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
import { IncidentStatus, IncidentPriority, PostCategory } from '../../../common/enums';

export class CreateIncidentDto {
  @ApiProperty({ example: 'Major road pothole causing accidents' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  title: string;

  @ApiProperty({ example: 'Large pothole on MG Road near Central Mall causing multiple accidents.' })
  @IsString()
  @MinLength(1)
  description: string;

  @ApiProperty({ example: 'infrastructure', enum: PostCategory })
  @IsString()
  category: string;

  @ApiProperty({ example: 28.6139, description: 'Latitude' })
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 77.209, description: 'Longitude' })
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional({ example: 'MG Road, Central Delhi' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: ['https://example.com/photo1.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaUrls?: string[];

  @ApiPropertyOptional({ enum: IncidentPriority })
  @IsOptional()
  @IsEnum(IncidentPriority)
  priority?: IncidentPriority;

  @ApiPropertyOptional({ example: 'John Doe' })
  @IsOptional()
  @IsString()
  reporterName?: string;

  @ApiPropertyOptional({ example: '+919876543210' })
  @IsOptional()
  @IsString()
  reporterPhone?: string;
}

export class UpdateIncidentDto {
  @ApiPropertyOptional({ enum: IncidentStatus })
  @IsOptional()
  @IsEnum(IncidentStatus)
  status?: IncidentStatus;

  @ApiPropertyOptional({ enum: IncidentPriority })
  @IsOptional()
  @IsEnum(IncidentPriority)
  priority?: IncidentPriority;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;
}

export class NearbyQueryDto {
  @ApiProperty({ example: 28.6139, description: 'Latitude' })
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 77.209, description: 'Longitude' })
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional({ example: 5000, description: 'Search radius in meters' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(50000)
  radius?: number;
}

/**
 * DTO for creating an incident from a promoted community post
 * Used internally by the Feed service when verification threshold is reached
 */
export class CreatePromotedIncidentDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsString()
  category: string;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsArray()
  mediaUrls?: string[];

  @IsString()
  reporterId: string;

  @IsString()
  communityPostId: string;

  @IsNumber()
  verificationCount: number;
}
