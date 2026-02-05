import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsEnum,
  IsNumber,
  Min,
  Max,
  ValidateNested,
  IsArray,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { UserRole } from '../../../common/enums';

export class EmergencyContactDto {
  @ApiProperty({ example: 'Dad' })
  @IsString()
  name: string;

  @ApiProperty({ example: '+919876543210' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'Father' })
  @IsString()
  relation: string;
}

export class CreateUserDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'SecurePass123!' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  fullName: string;

  @ApiPropertyOptional({ example: '+91-9876543210' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ enum: UserRole, default: UserRole.CITIZEN })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  // Profile fields
  @ApiPropertyOptional({ example: 'Engineer' })
  @IsOptional()
  @IsString()
  profession?: string;

  @ApiPropertyOptional({ example: '123 Main St, Mumbai' })
  @IsOptional()
  @IsString()
  address?: string;

  // Area-based assignment (for volunteers/authorities)
  @ApiPropertyOptional({ example: 'Mumbai Central' })
  @IsOptional()
  @IsString()
  registeredArea?: string;

  @ApiPropertyOptional({ example: 'mumbai-central' })
  @IsOptional()
  @IsString()
  registeredAreaId?: string;

  // Identity document
  @ApiPropertyOptional({ example: 'https://storage.googleapis.com/...' })
  @IsOptional()
  @IsString()
  identityDocumentUrl?: string;

  @ApiPropertyOptional({ enum: ['aadhaar', 'pan', 'driving_license', 'voter_id'] })
  @IsOptional()
  @IsString()
  identityDocumentType?: string;

  // Authority-specific fields
  @ApiPropertyOptional({ example: 'POLICE-MUM-001' })
  @IsOptional()
  @IsString()
  authorityCode?: string;

  @ApiPropertyOptional({ example: 'Police' })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({ example: 'AUTH-REG-12345' })
  @IsOptional()
  @IsString()
  registrationNumber?: string;
}

export class UpdateUserDto {
  @ApiPropertyOptional({ example: 'John Doe Updated' })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ example: '+91-9876543210' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiPropertyOptional({ example: 'Engineer' })
  @IsOptional()
  @IsString()
  profession?: string;

  @ApiPropertyOptional({ example: '123 Main St, Mumbai' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Mumbai Central' })
  @IsOptional()
  @IsString()
  registeredArea?: string;

  @ApiPropertyOptional({ example: 'mumbai-central' })
  @IsOptional()
  @IsString()
  registeredAreaId?: string;

  @ApiPropertyOptional({ example: 'https://storage.googleapis.com/...' })
  @IsOptional()
  @IsString()
  identityDocumentUrl?: string;

  @ApiPropertyOptional({ enum: ['aadhaar', 'pan', 'driving_license', 'voter_id'] })
  @IsOptional()
  @IsString()
  identityDocumentType?: string;

  @ApiPropertyOptional({ example: [{ name: 'Dad', phone: '+919876543210', relation: 'Father' }] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EmergencyContactDto)
  emergencyContacts?: EmergencyContactDto[];
}

export class UpdateLocationDto {
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
}
