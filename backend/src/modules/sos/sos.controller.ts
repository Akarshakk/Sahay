import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SOSService } from './sos.service';
import { CreateSOSDto, AddSOSActionDto, UpdateSOSDto, VolunteerRespondDto, AuthorityDispatchDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('sos')
@Controller('sos')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SOSController {
    constructor(private readonly sosService: SOSService) { }

    @Post('trigger')
    @ApiOperation({ summary: 'Trigger an SOS alert' })
    async triggerSOS(@Request() req: any, @Body() dto: CreateSOSDto) {
        const log = await this.sosService.create(req.user.id, dto);
        return {
            success: true,
            message: 'SOS Alert Triggered',
            data: log,
        };
    }

    @Post(':id/action')
    @ApiOperation({ summary: 'Log an action taken during SOS (e.g. Call 100)' })
    async addAction(
        @Param('id') id: string,
        @Request() req: any,
        @Body() dto: AddSOSActionDto,
    ) {
        const log = await this.sosService.addAction(id, req.user.id, dto);
        return {
            success: true,
            message: 'Action logged',
            data: log,
        };
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update SOS log (message, status)' })
    async updateSOS(
        @Param('id') id: string,
        @Request() req: any,
        @Body() dto: UpdateSOSDto,
    ) {
        const log = await this.sosService.update(id, req.user.id, dto);
        return {
            success: true,
            message: 'SOS updated',
            data: log,
        };
    }

    @Get('history')
    @ApiOperation({ summary: 'Get SOS history for current user' })
    async getHistory(@Request() req: any) {
        const logs = await this.sosService.getHistory(req.user.id);
        return {
            success: true,
            data: logs,
        };
    }

    @Get('active')
    @ApiOperation({ summary: 'Get all active SOS alerts (for authorities/volunteers)' })
    async getActiveAlerts() {
        const logs = await this.sosService.getActiveSOSAlerts();
        return {
            success: true,
            data: logs,
        };
    }

    @Get('nearby')
    @ApiOperation({ summary: 'Get nearby SOS alerts within a radius' })
    @ApiQuery({ name: 'latitude', required: true, type: Number })
    @ApiQuery({ name: 'longitude', required: true, type: Number })
    @ApiQuery({ name: 'radius', required: false, type: Number, description: 'Radius in km (default: 5)' })
    async getNearbyAlerts(
        @Query('latitude') latitude: number,
        @Query('longitude') longitude: number,
        @Query('radius') radius?: number,
    ) {
        const logs = await this.sosService.getNearbySOSAlerts(
            Number(latitude),
            Number(longitude),
            radius ? Number(radius) : 5,
        );
        return {
            success: true,
            data: logs,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get SOS details by ID' })
    async getSOSById(@Param('id') id: string) {
        const log = await this.sosService.getSOSById(id);
        return {
            success: true,
            data: log,
        };
    }

    @Get(':id/responders')
    @ApiOperation({ summary: 'Get all responders (volunteers and authorities) for an SOS' })
    async getResponders(@Param('id') id: string) {
        const responders = await this.sosService.getSOSResponders(id);
        return {
            success: true,
            data: responders,
        };
    }

    @Get('responders/nearby')
    @ApiOperation({ summary: 'Get nearby volunteers and authorities' })
    @ApiQuery({ name: 'latitude', required: true, type: Number })
    @ApiQuery({ name: 'longitude', required: true, type: Number })
    @ApiQuery({ name: 'radius', required: false, type: Number, description: 'Radius in km (default: 10)' })
    async getNearbyResponders(
        @Query('latitude') latitude: number,
        @Query('longitude') longitude: number,
        @Query('radius') radius?: number,
    ) {
        const responders = await this.sosService.getNearbyResponders(
            Number(latitude),
            Number(longitude),
            radius ? Number(radius) : 10,
        );
        return {
            success: true,
            data: responders,
        };
    }

    @Post(':id/volunteer-respond')
    @ApiOperation({ summary: 'Volunteer responds to SOS (clicks Help)' })
    async volunteerRespond(
        @Param('id') id: string,
        @Request() req: any,
        @Body() dto: VolunteerRespondDto,
    ) {
        const log = await this.sosService.addVolunteerResponse(id, req.user.id, dto);
        return {
            success: true,
            message: 'Volunteer response recorded',
            data: log,
        };
    }

    @Post(':id/authority-dispatch')
    @ApiOperation({ summary: 'Authority dispatches resources to SOS' })
    async authorityDispatch(
        @Param('id') id: string,
        @Request() req: any,
        @Body() dto: AuthorityDispatchDto,
    ) {
        const log = await this.sosService.addAuthorityDispatch(id, req.user.id, dto);
        return {
            success: true,
            message: 'Resources dispatched',
            data: log,
        };
    }
}

