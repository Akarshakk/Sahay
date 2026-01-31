import { Module, forwardRef } from '@nestjs/common';
import { FeedService } from './feed.service';
import { FeedController } from './feed.controller';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { IncidentsModule } from '../incidents/incidents.module';
import { UsersModule } from '../users/users.module';
import { WebsocketModule } from '../websocket/websocket.module';

@Module({
  imports: [
    forwardRef(() => IncidentsModule),
    UsersModule,
    WebsocketModule,
  ],
  providers: [FeedService, ChatService],
  controllers: [FeedController, ChatController],
  exports: [FeedService, ChatService],
})
export class FeedModule { }
