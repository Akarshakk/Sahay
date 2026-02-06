import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';

// Firebase Module
import { FirebaseModule } from './firebase';

// Feature Modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { IncidentsModule } from './modules/incidents/incidents.module';
import { FeedModule } from './modules/feed/feed.module';
import { WebsocketModule } from './modules/websocket/websocket.module';
import { MailModule } from './modules/mail/mail.module';
import { UploadModule } from './modules/upload/upload.module';
import { SOSModule } from './modules/sos/sos.module';
import { BroadcastsModule } from './modules/broadcasts/broadcasts.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { TranscriptionModule } from './modules/transcription/transcription.module';

@Module({
  imports: [
    // ============================================
    // CONFIGURATION MODULE
    // ============================================
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // ============================================
    // STATIC FILE SERVING (for uploaded documents)
    // ============================================
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),

    // ============================================
    // FIREBASE MODULE (Replaces TypeORM & Mongoose)
    // ============================================
    FirebaseModule,

    // ============================================
    // FEATURE MODULES
    // ============================================
    AuthModule,
    UsersModule,
    IncidentsModule,
    FeedModule, // Community Pulse - The Twitter-like feed
    WebsocketModule,
    MailModule,
    UploadModule,
    SOSModule,
    BroadcastsModule,
    TasksModule,
    TranscriptionModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule { }
