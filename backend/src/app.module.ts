import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';

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
    // PRIMARY DATABASE: PostgreSQL + PostGIS
    // Purpose: Users, Authentication, Official Incidents
    // ============================================
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('POSTGRES_HOST', 'localhost'),
        port: configService.get<number>('POSTGRES_PORT', 5432),
        username: configService.get<string>('POSTGRES_USER', 'civicsync'),
        password: configService.get<string>('POSTGRES_PASSWORD'),
        database: configService.get<string>('POSTGRES_DB', 'civicsync'),
        entities: [__dirname + '/modules/**/*.entity{.ts,.js}'],
        synchronize: configService.get<string>('NODE_ENV') === 'development',
        logging: configService.get<string>('NODE_ENV') === 'development',
        // PostGIS support is automatic with the postgis/postgis Docker image
      }),
    }),

    // ============================================
    // SECONDARY DATABASE: MongoDB
    // Purpose: Community Pulse (Twitter-like local feed)
    // ============================================
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>(
          'MONGODB_URI',
          'mongodb://localhost:27017/civicsync_community',
        ),
        // Connection options for production readiness
        retryWrites: true,
        w: 'majority',
      }),
    }),

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
export class AppModule {}
