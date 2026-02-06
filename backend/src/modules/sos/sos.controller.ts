import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SOSService } from './sos.service';
import { CreateSOSDto, AddSOSActionDto, UpdateSOSDto } from './dto';
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
}
