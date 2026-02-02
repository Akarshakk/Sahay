import { Controller, Post, Body, Get, Query, UseGuards, Req } from '@nestjs/common';
import { BroadcastsService } from './broadcasts.service';
import { CreateBroadcastDto } from './dto/create-broadcast.dto';
// Assuming AuthGuard exists, otherwise skip for MVP
// import { AuthGuard } from '../../common/guards/auth.guard';

@Controller('broadcasts')
export class BroadcastsController {
    constructor(private readonly broadcastsService: BroadcastsService) { }

    @Post()
    async create(@Body() createBroadcastDto: CreateBroadcastDto) {
        return this.broadcastsService.create(createBroadcastDto);
    }

    @Get()
    async findAll(@Query('region') region: string) {
        return this.broadcastsService.findAll(region);
    }
}
