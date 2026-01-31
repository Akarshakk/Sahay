import { Injectable, NotFoundException, ForbiddenException, Inject } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { ChatMessage } from './feed.interface';
import { EventsGateway } from '../websocket/events.gateway';

@Injectable()
export class ChatService {
  private db: admin.firestore.Firestore;
  private chatCollection: admin.firestore.CollectionReference;

  constructor(
    @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
    private readonly eventsGateway: EventsGateway,
  ) {
    this.db = admin.firestore(this.firebaseApp);
    this.chatCollection = this.db.collection('chat_messages');
  }

  async sendMessage(
    postId: string,
    userId: string,
    userName: string,
    message: string,
    replyToMessageId?: string,
  ): Promise<ChatMessage> {
    const messageRef = this.chatCollection.doc();
    const now = new Date();

    const chatMessage: ChatMessage = {
      id: messageRef.id,
      postId,
      authorId: userId,
      authorName: userName,
      message,
      replyToMessageId,
      reactions: [],
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };

    await messageRef.set(chatMessage);

    // Broadcast to WebSocket clients
    this.eventsGateway.server.emit('newChatMessage', {
      type: 'NEW_CHAT_MESSAGE',
      data: chatMessage,
      postId,
    });

    return chatMessage;
  }

  async getPostMessages(postId: string, limit = 50): Promise<ChatMessage[]> {
    const snapshot = await this.chatCollection
      .where('postId', '==', postId)
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => doc.data() as ChatMessage);
  }

  async getMessageReplies(messageId: string): Promise<ChatMessage[]> {
    const snapshot = await this.chatCollection
      .where('replyToMessageId', '==', messageId)
      .where('isActive', '==', true)
      .orderBy('createdAt', 'asc')
      .get();

    return snapshot.docs.map((doc) => doc.data() as ChatMessage);
  }

  async addReaction(messageId: string, userId: string): Promise<ChatMessage> {
    const messageRef = this.chatCollection.doc(messageId);
    const doc = await messageRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Message not found');
    }

    const message = doc.data() as ChatMessage;

    if (!message.reactions.includes(userId)) {
      message.reactions.push(userId);
      await messageRef.update({
        reactions: message.reactions,
        updatedAt: new Date(),
      });

      // Broadcast reaction
      this.eventsGateway.server.emit('messageReaction', {
        type: 'MESSAGE_REACTION',
        data: { messageId, userId, reactionCount: message.reactions.length },
      });
    }

    return message;
  }

  async deleteMessage(messageId: string, userId: string): Promise<void> {
    const messageRef = this.chatCollection.doc(messageId);
    const doc = await messageRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Message not found');
    }

    const message = doc.data() as ChatMessage;

    if (message.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own messages');
    }

    await messageRef.update({
      isActive: false,
      updatedAt: new Date(),
    });
  }
}
