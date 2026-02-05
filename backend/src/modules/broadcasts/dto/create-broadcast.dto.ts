import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';

export class CreateBroadcastDto {
    @IsString()
    @IsNotEmpty()
    title: string;

    @IsString()
    @IsNotEmpty()
    message: string;

    @IsString()
    @IsNotEmpty()
    region: string;

    @IsEnum(['Low', 'Medium', 'High', 'Critical'])
    priority: 'Low' | 'Medium' | 'High' | 'Critical';

    @IsOptional()
    @IsString()
    authorId?: string;
}
