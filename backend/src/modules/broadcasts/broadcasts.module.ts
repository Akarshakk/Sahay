import { Module } from '@nestjs/common';
import { BroadcastsController } from './broadcasts.controller';
import { BroadcastsService } from './broadcasts.service';
// WebsocketModule is what we export, NOT EventsModule
import { WebsocketModule } from '../websocket/websocket.module';

@Module({
    imports: [WebsocketModule],
    controllers: [BroadcastsController],
    providers: [BroadcastsService],
})
export class BroadcastsModule { }
