# 🚀 CivicSync API Documentation

## 📍 Base URL
```
http://localhost:3000/api/v1
```

## 🔐 Authentication
All protected endpoints require a JWT Bearer token:
```
Authorization: Bearer <your_jwt_token>
```

---

## 🐦 TWITTER-LIKE FEED FEATURES

### 1️⃣ Community Feed (Posts)

#### Create a Post (Like Tweeting)
```http
POST /feed/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "content": "Broken streetlight at Main Street corner",
  "category": "infrastructure",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "address": "123 Main St, Delhi",
  "mediaUrls": ["https://example.com/photo.jpg"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post created successfully",
  "data": {
    "_id": "507f1f77bcf86cd799439011",
    "content": "Broken streetlight at Main Street corner",
    "category": "infrastructure",
    "authorId": "user-uuid",
    "authorName": "John Doe",
    "location": {
      "type": "Point",
      "coordinates": [77.2090, 28.6139]
    },
    "verificationCount": 0,
    "createdAt": "2026-01-14T10:30:00Z"
  }
}
```

---

#### Get Nearby Feed (Geofenced Twitter Timeline)
```http
GET /feed?latitude=28.6139&longitude=77.2090&radius=2000&page=1&limit=20
Authorization: Bearer <token>
```

**Query Parameters:**
- `latitude` (required): Your latitude
- `longitude` (required): Your longitude  
- `radius` (optional): Search radius in meters (default: 2000m = 2km)
- `page` (optional): Page number (default: 1)
- `limit` (optional): Posts per page (default: 20)
- `category` (optional): Filter by category

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "content": "Pothole on Highway 1",
      "distance": 450.5,
      "verificationCount": 3,
      "authorName": "Jane Smith",
      "createdAt": "2026-01-14T09:15:00Z"
    }
  ],
  "meta": {
    "total": 45,
    "radius": 2000,
    "center": { "lat": 28.6139, "lng": 77.2090 }
  }
}
```

---

#### Get Trending Posts
```http
GET /feed/trending?latitude=28.6139&longitude=77.2090&limit=10
Authorization: Bearer <token>
```

**Response:** Most verified posts in last 24 hours within 2km

---

#### Verify a Post (Like/Upvote)
```http
POST /feed/:postId/verify
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "promoted": false,
  "post": {
    "verificationCount": 4
  }
}
```

**Note:** If `verificationCount >= 5`, the post is automatically promoted to an official incident:
```json
{
  "success": true,
  "promoted": true,
  "incidentId": "incident-uuid",
  "message": "Post promoted to official incident"
}
```

---

#### Get My Posts
```http
GET /feed/my-posts
Authorization: Bearer <token>
```

---

#### Delete a Post
```http
DELETE /feed/:postId
Authorization: Bearer <token>
```

---

## 💬 TWITTER-LIKE CHAT/COMMENTS

### 2️⃣ Real-time Chat on Posts

#### Send a Comment/Message
```http
POST /chat/:postId/messages
Authorization: Bearer <token>
Content-Type: application/json

{
  "message": "I saw this too! It's been like this for 3 days.",
  "replyToMessageId": "optional-parent-message-id"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Message sent",
  "data": {
    "_id": "60d5ec49f1b2c72b8c8e4a1b",
    "postId": "507f1f77bcf86cd799439011",
    "authorId": "user-uuid",
    "authorName": "John Doe",
    "message": "I saw this too! It's been like this for 3 days.",
    "reactions": [],
    "createdAt": "2026-01-14T10:45:00Z"
  }
}
```

**🔴 Real-time:** This message is instantly broadcast via WebSocket to all users viewing the post!

---

#### Get All Comments for a Post
```http
GET /chat/:postId/messages?limit=50
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "60d5ec49f1b2c72b8c8e4a1b",
      "authorName": "John Doe",
      "message": "I saw this too!",
      "reactions": ["user-1", "user-2"],
      "createdAt": "2026-01-14T10:45:00Z"
    },
    {
      "_id": "60d5ec49f1b2c72b8c8e4a2c",
      "authorName": "Jane Smith",
      "message": "Same here, authorities should fix this",
      "replyToMessageId": "60d5ec49f1b2c72b8c8e4a1b",
      "reactions": ["user-3"],
      "createdAt": "2026-01-14T10:47:00Z"
    }
  ],
  "count": 2
}
```

---

#### Get Threaded Replies
```http
GET /chat/messages/:messageId/replies
Authorization: Bearer <token>
```

**Response:** All replies to a specific message (threaded conversations like Twitter)

---

#### React to a Message (Heart/Like)
```http
POST /chat/messages/:messageId/react
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Reaction added",
  "data": {
    "reactionCount": 3
  }
}
```

**🔴 Real-time:** Reaction count updates instantly via WebSocket!

---

#### Delete a Message
```http
DELETE /chat/messages/:messageId
Authorization: Bearer <token>
```

---

## 🔌 WEBSOCKET EVENTS (Real-time Chat)

### Connect to WebSocket
```javascript
const socket = io('http://localhost:3000', {
  auth: {
    token: 'your-jwt-token'
  }
});

// Join a location-based room
socket.emit('joinLocation', {
  latitude: 28.6139,
  longitude: 77.2090
});
```

### Listen for Events

#### New Chat Message
```javascript
socket.on('newChatMessage', (data) => {
  console.log('New message:', data);
  // {
  //   type: 'NEW_CHAT_MESSAGE',
  //   data: { message object },
  //   postId: '507f1f77bcf86cd799439011'
  // }
});
```

#### Message Reaction
```javascript
socket.on('messageReaction', (data) => {
  console.log('New reaction:', data);
  // {
  //   type: 'MESSAGE_REACTION',
  //   data: {
  //     messageId: '60d5ec49f1b2c72b8c8e4a1b',
  //     userId: 'user-uuid',
  //     reactionCount: 5
  //   }
  // }
});
```

#### New Post in Your Area
```javascript
socket.on('newPost', (data) => {
  console.log('New post nearby:', data);
});
```

#### Post Verified
```javascript
socket.on('postVerified', (data) => {
  console.log('Post verification:', data);
  // { postId, verificationCount, promoted }
});
```

---

## 🚨 OFFICIAL INCIDENTS

#### Get Nearby Incidents
```http
GET /incidents/nearby?latitude=28.6139&longitude=77.2090&radius=5000
Authorization: Bearer <token>
```

#### Create Incident (Authorities Only)
```http
POST /incidents
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Major traffic accident",
  "description": "Multi-vehicle collision",
  "category": "accident",
  "priority": "high",
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

---

## 👤 AUTHENTICATION

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe",
  "phoneNumber": "+919876543210",
  "role": "citizen"
}
```

**Roles:** `citizen`, `volunteer`, `authority`, `admin`

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "fullName": "John Doe",
      "role": "citizen"
    }
  }
}
```

---

## 📊 USER PROFILE

#### Get My Profile
```http
GET /users/me
Authorization: Bearer <token>
```

#### Update Location
```http
PUT /users/me/location
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

---

## 🎯 CATEGORIES

- `infrastructure` - Roads, streetlights, utilities
- `safety` - Crime, suspicious activity
- `health` - Medical emergencies, sanitation
- `environment` - Pollution, waste
- `accident` - Traffic accidents
- `other` - Miscellaneous

---

## 🚀 HOW TO START THE APP

### Option 1: With Databases (Full Features)
```bash
# Start PostgreSQL + MongoDB
docker compose up -d

# Run the app
npm run start:dev

# Access Swagger docs
open http://localhost:3000/api/docs
```

### Option 2: Mock Mode (No Database)
```bash
# Run without databases
npx ts-node src/main-no-db.ts

# Access health check
curl http://localhost:3000/api/v1/health
```

---

## 📱 FLUTTER INTEGRATION

Update your Flutter app's API base URL:
```dart
const String apiBaseUrl = 'http://localhost:3000/api/v1';
```

For WebSocket (real-time chat):
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io('http://localhost:3000', <String, dynamic>{
  'transports': ['websocket'],
  'auth': {'token': yourJwtToken}
});

socket.on('newChatMessage', (data) {
  print('New message: $data');
});
```

---

## 🐛 TROUBLESHOOTING

**Problem:** "Cannot get /api/docs"
- **Solution:** You need to start the full app with databases. Swagger is not available in mock mode.

**Problem:** Docker not installed
- **Solution:** Install Docker Desktop for macOS from docker.com

**Problem:** Port 3000 already in use
- **Solution:** `lsof -ti:3000 | xargs kill -9`

---

## 📞 SUPPORT

For issues, check:
1. `README.md` - Setup instructions
2. `IMPLEMENTATION.md` - Technical architecture
3. Console logs - Backend shows detailed logs

---

**🎉 Your Twitter-like feed with real-time chat is ready!**
