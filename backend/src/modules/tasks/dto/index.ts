import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsArray,
  Min,
  Max,
  MinLength,
  MaxLength,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTaskDto {
  @ApiProperty({ example: 'Clean the community park' })
  @IsString()
  @MinLength(5)
  @MaxLength(100)
  title: string;

  @ApiProperty({ example: 'Help clean and beautify the local community park' })
  @IsString()
  @MinLength(10)
  @MaxLength(500)
  description: string;

  @ApiProperty({ example: 'Mumbai Central' })
  @IsString()
  region: string;

  @ApiProperty({ example: 'mumbai-central' })
  @IsString()
  areaId: string;

  @ApiPropertyOptional({ enum: ['low', 'medium', 'high'], default: 'medium' })
  @IsOptional()
  @IsEnum(['low', 'medium', 'high'])
  priority?: 'low' | 'medium' | 'high';

  @ApiProperty({ example: 100, description: 'Points awarded for completing task' })
  @IsNumber()
  @Min(10)
  @Max(1000)
  rewardPoints: number;

  @ApiPropertyOptional({ example: 'https://...' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ example: ['vol-123', 'vol-456'] })
  @IsOptional()
  @IsArray()
  assignedTo?: string[];

  @ApiPropertyOptional({ example: '2026-02-20T10:00:00Z' })
  @IsOptional()
  @IsDateString()
  deadline?: string;
}

export class UpdateTaskDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEnum(['low', 'medium', 'high'])
  priority?: 'low' | 'medium' | 'high';

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rewardPoints?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  assignedTo?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsEnum(['open', 'in_progress', 'completed', 'verified'])
  status?: 'open' | 'in_progress' | 'completed' | 'verified';
}

export class SubmitTaskDto {
  @ApiProperty({ example: 'task-123' })
  @IsString()
  taskId: string;

  @ApiProperty({ example: 'https://...' })
  @IsString()
  submissionImageUrl: string;

  @ApiPropertyOptional({ example: 'I completed the task as requested' })
  @IsOptional()
  @IsString()
  submissionNotes?: string;
}

export class VerifyTaskDto {
  @ApiProperty({ example: 'submission-123' })
  @IsString()
  submissionId: string;

  @ApiProperty({ enum: ['verified', 'rejected'] })
  @IsEnum(['verified', 'rejected'])
  status: 'verified' | 'rejected';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
