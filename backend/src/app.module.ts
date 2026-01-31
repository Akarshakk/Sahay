import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

// Firebase Module
import { FirebaseModule } from './firebase';

// Feature Modules
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { IncidentsModule } from './modules/incidents/incidents.module';
import { FeedModule } from './modules/feed/feed.module';
import { WebsocketModule } from './modules/websocket/websocket.module';

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
  ],
  controllers: [],
  providers: [],
})
export class AppModule { }
