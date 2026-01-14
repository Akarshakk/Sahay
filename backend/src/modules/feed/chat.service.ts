import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ChatMessage, ChatMessageDocument } from './schemas/chat-message.schema';
import { EventsGateway } from '../websocket/events.gateway';

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(ChatMessage.name)
    private readonly chatMessageModel: Model<ChatMessageDocument>,
    private readonly eventsGateway: EventsGateway,
  ) {}

  /**
   * Send a message in a post's chat
   */
  async sendMessage(
    postId: string,
    userId: string,
    userName: string,
    message: string,
    replyToMessageId?: string,
  ): Promise<ChatMessageDocument> {
    const chatMessage = new this.chatMessageModel({
      postId,
      authorId: userId,
      authorName: userName,
      message,
      replyToMessageId,
      reactions: [],
      isActive: true,
    });

    const saved = await chatMessage.save();

    // Broadcast to WebSocket clients
    this.eventsGateway.server.emit('newChatMessage', {
      type: 'NEW_CHAT_MESSAGE',
      data: saved,
      postId,
    });

    return saved;
  }

  /**
   * Get all messages for a post (Twitter-like thread)
   */
  async getPostMessages(
    postId: string,
    limit = 50,
  ): Promise<ChatMessageDocument[]> {
    return this.chatMessageModel
      .find({ postId, isActive: true })
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();
  }

  /**
   * Get threaded replies to a message
   */
  async getMessageReplies(messageId: string): Promise<ChatMessageDocument[]> {
    return this.chatMessageModel
      .find({ replyToMessageId: messageId, isActive: true })
      .sort({ createdAt: 1 })
      .exec();
  }

  /**
   * Add reaction to message
   */
  async addReaction(
    messageId: string,
    userId: string,
  ): Promise<ChatMessageDocument> {
    const message = await this.chatMessageModel.findById(messageId);
    
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (!message.reactions.includes(userId)) {
      message.reactions.push(userId);
      await message.save();

      // Broadcast reaction
      this.eventsGateway.server.emit('messageReaction', {
        type: 'MESSAGE_REACTION',
        data: { messageId, userId, reactionCount: message.reactions.length },
      });
    }

    return message;
  }

  /**
   * Delete message (author only)
   */
  async deleteMessage(messageId: string, userId: string): Promise<void> {
    const message = await this.chatMessageModel.findById(messageId);

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own messages');
    }

    message.isActive = false;
    await message.save();
  }
}
