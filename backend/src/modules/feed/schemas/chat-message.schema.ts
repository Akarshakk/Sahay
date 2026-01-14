import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

/**
 * ChatMessage Schema - Real-time chat for Community Pulse
 * Twitter-like threaded discussions on posts
 */
@Schema({ timestamps: true })
export class ChatMessage {
  _id: Types.ObjectId;

  // Reference to the community post this chat belongs to
  @Prop({ required: true })
  postId: string; // MongoDB ObjectId of CommunityPost

  // Author information
  @Prop({ required: true })
  authorId: string; // PostgreSQL UUID

  @Prop({ required: true })
  authorName: string;

  @Prop()
  authorAvatar: string;

  // Message content
  @Prop({ required: true, maxlength: 500 })
  message: string;

  // Threading (replies)
  @Prop()
  replyToMessageId: string; // ObjectId of parent message

  // Reactions
  @Prop({ type: [String], default: [] })
  reactions: string[]; // Array of user IDs who reacted

  // Soft delete
  @Prop({ default: true })
  isActive: boolean;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

export type ChatMessageDocument = ChatMessage & Document;
export const ChatMessageSchema = SchemaFactory.createForClass(ChatMessage);

// Indexes
ChatMessageSchema.index({ postId: 1, createdAt: -1 });
ChatMessageSchema.index({ authorId: 1 });
ChatMessageSchema.index({ replyToMessageId: 1 });
