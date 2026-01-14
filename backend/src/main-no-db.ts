import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  // Simple Express app without database connections
  const express = require('express');
  const app = express();
  
  app.use(express.json());
  
  // CORS
  app.use((req: any, res: any, next: any) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    if (req.method === 'OPTIONS') {
      return res.sendStatus(200);
    }
    next();
  });
  
  // Health check
  app.get('/api/v1/health', (req: any, res: any) => {
    res.json({
      status: 'ok',
      message: 'CivicSync Backend API is running (No Database Mode)',
      timestamp: new Date().toISOString(),
      docs: 'Start databases with Docker to access full API'
    });
  });
  
  // Mock endpoints
  app.post('/api/v1/auth/register', (req: any, res: any) => {
    res.status(201).json({
      message: 'User registered (mock)',
      user: { id: '123', email: req.body.email, role: req.body.role || 'citizen' },
      accessToken: 'mock-jwt-token'
    });
  });
  
  app.post('/api/v1/auth/login', (req: any, res: any) => {
    res.json({
      message: 'Login successful (mock)',
      user: { id: '123', email: req.body.email, role: 'citizen' },
      accessToken: 'mock-jwt-token'
    });
  });
  
  app.get('/api/v1/feed', (req: any, res: any) => {
    res.json({
      data: [
        {
          _id: '1',
          content: 'Mock community post - broken streetlight',
          category: 'infrastructure',
          location: { type: 'Point', coordinates: [77.209, 28.6139] },
          verificationCount: 3,
          createdAt: new Date()
        }
      ],
      meta: {
        total: 1,
        radius: 2000,
        center: { lat: req.query.latitude, lng: req.query.longitude }
      }
    });
  });
  
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    logger.log(`🚀 CivicSync API (No-DB Mode) running on: http://localhost:${port}`);
    logger.log(`📚 Health check: http://localhost:${port}/api/v1/health`);
    logger.log(`⚠️  To use full features, start databases with: docker compose up -d`);
  });
}

bootstrap();
