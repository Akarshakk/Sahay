import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('chat')
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  /**
   * POST /chat/:postId/messages
   * Send a message in a post's chat (Twitter-like comments)
   */
  @Post(':postId/messages')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Send a chat message on a post' })
  async sendMessage(
    @Param('postId') postId: string,
    @Request() req: any,
    @Body() body: { message: string; replyToMessageId?: string },
  ) {
    const message = await this.chatService.sendMessage(
      postId,
      req.user.id,
      req.user.name || 'User',
      body.message,
      body.replyToMessageId,
    );

    return {
      success: true,
      message: 'Message sent',
      data: message,
    };
  }

  /**
   * GET /chat/:postId/messages
   * Get all messages for a post
   */
  @Get(':postId/messages')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get chat messages for a post' })
  async getPostMessages(
    @Param('postId') postId: string,
    @Query('limit') limit?: number,
  ) {
    const messages = await this.chatService.getPostMessages(postId, limit);
    
    return {
      success: true,
      data: messages,
      count: messages.length,
    };
  }

  /**
   * GET /chat/messages/:messageId/replies
   * Get threaded replies to a message
   */
  @Get('messages/:messageId/replies')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get replies to a message' })
  async getMessageReplies(@Param('messageId') messageId: string) {
    const replies = await this.chatService.getMessageReplies(messageId);
    
    return {
      success: true,
      data: replies,
    };
  }

  /**
   * POST /chat/messages/:messageId/react
   * Add reaction to a message (like on Twitter)
   */
  @Post('messages/:messageId/react')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'React to a message' })
  async addReaction(
    @Param('messageId') messageId: string,
    @Request() req: any,
  ) {
    const message = await this.chatService.addReaction(messageId, req.user.id);
    
    return {
      success: true,
      message: 'Reaction added',
      data: { reactionCount: message.reactions.length },
    };
  }

  /**
   * DELETE /chat/messages/:messageId
   * Delete a message
   */
  @Delete('messages/:messageId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete your message' })
  async deleteMessage(
    @Param('messageId') messageId: string,
    @Request() req: any,
  ) {
    await this.chatService.deleteMessage(messageId, req.user.id);
    
    return {
      success: true,
      message: 'Message deleted',
    };
  }
}
