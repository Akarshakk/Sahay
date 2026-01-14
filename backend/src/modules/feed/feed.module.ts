import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CommunityPost, CommunityPostSchema } from './schemas/community-post.schema';
import { ChatMessage, ChatMessageSchema } from './schemas/chat-message.schema';
import { FeedService } from './feed.service';
import { FeedController } from './feed.controller';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { IncidentsModule } from '../incidents/incidents.module';
import { UsersModule } from '../users/users.module';
import { WebsocketModule } from '../websocket/websocket.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CommunityPost.name, schema: CommunityPostSchema },
      { name: ChatMessage.name, schema: ChatMessageSchema },
    ]),
    forwardRef(() => IncidentsModule), // For incident promotion
    UsersModule, // For user validation
    WebsocketModule, // For real-time chat
  ],
  providers: [FeedService, ChatService],
  controllers: [FeedController, ChatController],
  exports: [FeedService, ChatService],
})
export class FeedModule {}
