import { Controller, Post, Get, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SOSService } from './sos.service';
import { CreateSOSDto, AddSOSActionDto } from './dto';
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

    @Get('history')
    @ApiOperation({ summary: 'Get SOS history for current user' })
    async getHistory(@Request() req: any) {
        const logs = await this.sosService.getHistory(req.user.id);
        return {
            success: true,
            data: logs,
        };
    }
}
