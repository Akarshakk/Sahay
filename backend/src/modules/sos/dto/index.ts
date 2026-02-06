import { IsString, IsNotEmpty, IsNumber, IsOptional, IsArray, ValidateNested, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSOSDto {
    @ApiProperty()
    @IsNumber()
    latitude: number;

    @ApiProperty()
    @IsNumber()
    longitude: number;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    address?: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    message?: string;

    @ApiProperty({ required: false })
    @IsNumber()
    @IsOptional()
    batteryLevel?: number;

    @ApiProperty({ enum: ['POLICE', 'AMBULANCE', 'FIRE', 'CONTACTS', 'Custom'] })
    @IsString()
    type: 'POLICE' | 'AMBULANCE' | 'FIRE' | 'CONTACTS' | 'Custom';
}

export class UpdateSOSDto {
    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    message?: string;

    @ApiProperty({ required: false, enum: ['TRIGGERED', 'RESOLVED', 'FALSE_ALARM'] })
    @IsString()
    @IsOptional()
    status?: 'TRIGGERED' | 'RESOLVED' | 'FALSE_ALARM';
}

export class AddSOSActionDto {
    @ApiProperty()
    @IsString()
    @IsNotEmpty()
    action: string;

    @ApiProperty({ required: false })
    @IsString()
    @IsOptional()
    details?: string;
}
