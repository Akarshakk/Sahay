import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { IncidentsService } from './incidents.service';
import { CreateIncidentDto, UpdateIncidentDto, NearbyQueryDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole, IncidentStatus } from '../../common/enums';

@ApiTags('incidents')
@Controller('incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) { }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new incident report' })
  async create(@Request() req: any, @Body() createIncidentDto: CreateIncidentDto) {
    return this.incidentsService.create(createIncidentDto, req.user.id);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all incidents with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, enum: IncidentStatus })
  async findAll(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('status') status?: IncidentStatus,
  ) {
    return this.incidentsService.findAll(Number(page), Number(limit), status);
  }

  @Get('nearby')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get incidents near a location' })
  async findNearby(@Query() query: NearbyQueryDto) {
    return this.incidentsService.findNearby(
      query.latitude,
      query.longitude,
      query.radius,
    );
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get incident by ID' })
  async findById(@Param('id') id: string) {
    return this.incidentsService.findById(id);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHORITY, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update incident (Authority/Admin only)' })
  async update(
    @Param('id') id: string,
    @Body() updateIncidentDto: UpdateIncidentDto,
  ) {
    return this.incidentsService.update(id, updateIncidentDto);
  }

  @Put(':id/assign/:authorityId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Assign incident to authority (Admin only)' })
  async assignToAuthority(
    @Param('id') id: string,
    @Param('authorityId') authorityId: string,
  ) {
    return this.incidentsService.assignToAuthority(id, authorityId);
  }
}
