# Sahay Backend API

NestJS backend with Firebase Firestore for the Sahay crisis response platform.

## Quick Start

```bash
npm install
npm start
```

Server runs on `http://localhost:3000`

## Environment Variables

Create `.env` file:

```env
PORT=3000
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
DEFAULT_SEARCH_RADIUS_METERS=10000
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Phone-based login |
| POST | `/api/auth/verify` | Verify OTP |
| GET | `/api/feed/nearby` | Get posts within radius |
| POST | `/api/feed` | Create new post |
| POST | `/api/feed/:id/verify` | Verify a post |
| GET | `/api/incidents` | Get incidents |
| POST | `/api/incidents` | Report incident |

## Tech Stack

- NestJS + TypeScript
- Firebase Admin SDK
- JWT Authentication
