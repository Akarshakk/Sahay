import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../../common/enums';

export class RegisterDto {
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

  @ApiPropertyOptional({ example: '123 Main St' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Engineer' })
  @IsOptional()
  @IsString()
  profession?: string;

  @ApiPropertyOptional({ example: '1990-01-01' })
  @IsOptional()
  @IsString()
  dob?: string;

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

export class LoginDto {
  @ApiProperty({ example: '9876543210' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'SecurePass123!' })
  @IsString()
  password: string;
}
