# 🚀 Sahay - Crisis Response Platform with Twitter-Like Community Feed

## ✅ What's Been Implemented

### 🐦 Twitter-Like Community Features

#### 1. **Community Pulse Feed** (Twitter-Style Feed)
- ✅ Create posts with geolocation (like tweeting)
- ✅ View nearby posts within 2km radius (geofenced timeline)
- ✅ Category-based posts (infrastructure, safety, health, environment, accident)
- ✅ Verification/upvoting system (5+ votes = promote to official incident)
- ✅ Trending posts (most verified in last 24 hours)
- ✅ Real-time updates via WebSocket

#### 2. **Real-Time Chat on Posts** (Twitter-Style Comments)
- ✅ Comment/reply to posts
- ✅ Threaded conversations
- ✅ Reactions (hearts/likes) on messages
- ✅ Live message updates via WebSocket
- ✅ Author identification with avatars

#### 3. **Gamification & Verification**
- ✅ Volunteers can verify posts
- ✅ Auto-promotion to official incidents at 5+ verifications
- ✅ Verification count tracking
- ✅ Promoted posts badge

### 🏗️ Architecture

**Frontend**: Flutter Web (running on Chrome)
**Backend**: NestJS + Express Mock Server
**Databases**: PostgreSQL + MongoDB (optional - mock server works without them)
**Real-time**: Socket.io WebSockets
**State Management**: Flutter Riverpod

---

## 🎯 Current Status

### ✅ Running Right Now:

1. **Flutter Frontend** on Chrome
   - URL: Check Chrome browser
   - Debug tools: http://127.0.0.1:58403/b8uN8rpzEmg=/devtools

2. **Mock Backend Server** on port 3000
   - HTTP API: http://localhost:3000/api/v1
   - WebSocket: ws://localhost:3000
   - Health check: http://localhost:3000/api/v1/health

### 🎨 UI Features Integrated:

- **Home Screen**: "Community" button to access feed
- **Community Feed Screen**: Twitter-like feed with posts
- **Post Creation Screen**: Create new posts with categories
- **Post Chat Screen**: Real-time chat on each post
- **Verification System**: Tap "Verify" to upvote posts

---

## 📱 How to Use the App

### 1. **Access Community Feed**
   - Open the app in Chrome (already running)
   - Click the **"Community"** button on home screen
   - Or tap **"Verify"** if you're a volunteer

### 2. **View Nearby Posts**
   - See posts from people within 2km of your location
   - Posts show:
     - Author name and avatar
     - Category (infrastructure, safety, etc.)
     - Content/description
     - Location/address
     - Distance from you
     - Verification count
     - Promoted badge (if 5+ verifications)

### 3. **Create a New Post**
   - Tap the red **"New Post"** button (bottom right)
   - Select a category (infrastructure, safety, health, environment, accident, other)
   - Write a description
   - Your location is automatically captured
   - Tap **"POST"**

### 4. **Verify/Upvote Posts**
   - Tap **"verified"** button on any post
   - Your verification is counted
   - Post promoted to official incident at 5+ verifications

### 5. **Chat on Posts**
   - Tap any post to open it
   - View existing comments
   - Write a comment in the text field
   - Tap send button (red circle)
   - React to messages with hearts ❤️
   - See real-time updates as others comment

---

## 🔌 API Endpoints Available

### Authentication
```http
POST /api/v1/auth/register
POST /api/v1/auth/login
```

### Community Feed
```http
POST /api/v1/feed/create           # Create a post
GET  /api/v1/feed                  # Get nearby feed
POST /api/v1/feed/:id/verify       # Verify/upvote a post
GET  /api/v1/feed/trending         # Get trending posts
```

### Real-Time Chat
```http
POST /api/v1/chat/:postId/messages           # Send a message
GET  /api/v1/chat/:postId/messages           # Get all messages
POST /api/v1/chat/messages/:messageId/react  # React to a message
```

### Incidents
```http
GET /api/v1/incidents/nearby       # Get promoted incidents
```

---

## 🧪 Testing the Features

### Test Scenario 1: Create & Verify a Post
1. Click "Community" on home screen
2. Click "New Post" button
3. Select "infrastructure" category
4. Type: "Broken streetlight on XYZ Street"
5. Click "POST"
6. Wait for post to appear in feed
7. Click "verified" button multiple times (5+ times)
8. Post should get promoted badge

### Test Scenario 2: Real-Time Chat
1. Click any post in the feed
2. Type a comment: "I saw this too!"
3. Click send
4. Your message appears instantly
5. Click the heart icon to react
6. Open same post in another browser window to see real-time sync

### Test Scenario 3: View Trending Posts
1. In feed screen, posts with higher verification counts appear first
2. Scroll to see posts sorted by popularity

---

## 🛠️ Development Commands

### Flutter (Frontend)
```bash
# Hot reload (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
# Quit (press 'q' in terminal)

# Manual restart
flutter run -d chrome
```

### Backend
```bash
# Currently running mock server
# To restart:
cd backend
node src/main-mock.js

# To run full server with databases (requires Docker):
docker compose up -d
npm run start:dev
```

---

## 📊 Mock Data Available

The mock server provides sample posts:

1. **Post 1**: "Broken streetlight on Main Street..." (3 verifications)
2. **Post 2**: "Pothole on highway..." (7 verifications, PROMOTED)
3. **Post 3**: "Garbage not collected..." (2 verifications)

Each post has mock chat messages you can view.

---

## 🔴 Real-Time Features

The app uses WebSocket for live updates:

- ✅ New posts appear instantly
- ✅ Verification counts update live
- ✅ Chat messages broadcast in real-time
- ✅ Reactions update immediately
- ✅ Promotion notifications

---

## 📱 Mobile-Ready Features

All features work on web and are ready for mobile:

- ✅ Location services integration
- ✅ Pull-to-refresh on feed
- ✅ Infinite scroll (pagination ready)
- ✅ Responsive UI
- ✅ Touch-friendly buttons
- ✅ Bottom sheet modals

---

## 🚀 Next Steps (If Needed)

### Option A: Add Real Databases
```bash
# Install Docker Desktop
# Then run:
cd backend
docker compose up -d
npm run start:dev
```

This enables:
- Persistent data
- Actual geospatial queries (PostGIS)
- MongoDB aggregations
- Full authentication

### Option B: Deploy
```bash
# Frontend
flutter build web

# Backend
npm run build
npm run start:prod
```

---

## 🎉 Success Indicators

You've successfully implemented a Twitter-like community feed if:

- ✅ You can create posts with location
- ✅ You can see posts from others nearby
- ✅ You can verify/upvote posts
- ✅ Posts get promoted at 5+ verifications
- ✅ You can chat on posts
- ✅ You can react to messages
- ✅ Updates happen in real-time

---

## 📞 Support & Documentation

- **API Docs**: `backend/API_DOCUMENTATION.md`
- **Architecture**: `ARCHITECTURE.md`
- **Implementation**: `backend/IMPLEMENTATION.md`

---

## 🏆 Features Summary

| Feature | Status | Description |
|---------|--------|-------------|
| Post Creation | ✅ | Create posts with category, location, description |
| Geofenced Feed | ✅ | See posts within 2km radius |
| Verification | ✅ | Upvote posts to validate them |
| Auto-Promotion | ✅ | 5+ verifications → official incident |
| Real-Time Chat | ✅ | Comment and discuss on posts |
| Message Reactions | ✅ | React with hearts/likes |
| WebSocket Updates | ✅ | Live feed and chat updates |
| Trending Posts | ✅ | Most verified posts in 24hrs |
| Categories | ✅ | 6 categories with icons |
| Location Services | ✅ | Auto-detect user location |

---

**Your Twitter-like crisis response platform is ready! 🎉**

Open Chrome and explore the Community Feed! 🐦
