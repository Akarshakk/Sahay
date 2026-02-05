import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto, UpdateLocationDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile' })
  async getCurrentUser(@Request() req: any) {
    return this.usersService.findById(req.user.id);
  }

  @Put('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update current user profile' })
  async updateCurrentUser(@Request() req: any, @Body() updateUserDto: UpdateUserDto) {
    try {
      console.log('DEBUG: updateCurrentUser called with:', JSON.stringify(updateUserDto, null, 2));
      return await this.usersService.update(req.user.id, updateUserDto);
    } catch (error) {
      console.error('Error in updateCurrentUser:', error);
      throw error;
    }
  }

  @Put('me/location')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user location' })
  async updateLocation(@Request() req: any, @Body() locationDto: UpdateLocationDto) {
    return this.usersService.updateLocation(
      req.user.id,
      locationDto.latitude,
      locationDto.longitude,
    );
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user by ID' })
  async getUserById(@Param('id') id: string) {
    const user = await this.usersService.findById(id);
    // Remove sensitive data
    const { passwordHash, ...result } = user;
    return result;
  }
}
