# CivicSync Backend API

> Crisis Response Platform - Hybrid PostgreSQL + MongoDB Backend

## Architecture Overview

This backend uses a **hybrid database architecture**:

| Database | Purpose | Features |
|----------|---------|----------|
| **PostgreSQL + PostGIS** | Users, Auth, Official Incidents | ACID transactions, geospatial queries |
| **MongoDB** | Community Pulse (Twitter-like feed) | Flexible schema, 2dsphere indexes |

## Tech Stack

- **Framework**: NestJS (Node.js/TypeScript)
- **Primary DB**: PostgreSQL 15 + PostGIS 3.4
- **Secondary DB**: MongoDB 7.0
- **ORM**: TypeORM (PostgreSQL), Mongoose (MongoDB)
- **Auth**: JWT with Passport.js
- **Real-time**: Socket.io WebSockets
- **Docs**: Swagger/OpenAPI

## Quick Start

### 1. Start Databases

```bash
# Start PostgreSQL + MongoDB with Docker
docker-compose up -d

# Wait for databases to be ready
docker-compose ps
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your settings
```

### 4. Run the Server

```bash
# Development mode
npm run start:dev

# Production mode
npm run build
npm run start:prod
```

### 5. Access API

- **API Base**: http://localhost:3000/api/v1
- **Swagger Docs**: http://localhost:3000/api/docs

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login user |

### Community Pulse (MongoDB)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/feed/create` | Create a local post |
| GET | `/feed?lat=...&lng=...` | Get nearby posts (2km radius) |
| POST | `/feed/:id/verify` | Verify a post (volunteers) |
| GET | `/feed/:id` | Get single post |
| DELETE | `/feed/:id` | Delete own post |

### Incidents (PostgreSQL)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/incidents` | Create incident report |
| GET | `/incidents` | List all incidents |
| GET | `/incidents/nearby` | Get nearby incidents |
| GET | `/incidents/:id` | Get incident details |
| PUT | `/incidents/:id` | Update incident (authority) |

## Key Features

### 🌍 Geospatial Privacy

**Hyper-local feeds**: Users ONLY see posts within 2km of their current location.

```typescript
// MongoDB $geoNear query
{
  $geoNear: {
    near: { type: 'Point', coordinates: [longitude, latitude] },
    maxDistance: 2000, // 2km in meters
    spherical: true,
    distanceField: 'distance'
  }
}
```

### 🎮 Verification Gamification

1. **Citizens** post local issues
2. **Volunteers** verify posts (upvote)
3. Posts with **5+ verifications** are auto-promoted to official incidents

```typescript
// Promotion logic in FeedService
if (post.verificationCount >= 5 && !post.isPromoted) {
  await this.promoteToIncident(post);
}
```

### 🔄 Hybrid Database Flow

```
[User Posts Issue] 
      ↓
[MongoDB: community_posts]
      ↓
[Volunteers Verify (5+)]
      ↓
[Auto-Promote]
      ↓
[PostgreSQL: incidents]
      ↓
[Authorities View & Respond]
```

## Database Schemas

### MongoDB: CommunityPost

```javascript
{
  content: String,
  category: 'infrastructure' | 'safety' | 'sanitation' | 'traffic' | 'environment' | 'other',
  location: {
    type: 'Point',
    coordinates: [longitude, latitude]  // GeoJSON format
  },
  authorId: String,  // PostgreSQL user UUID
  verifications: [{
    odeclareId: String,
    verifiedAt: Date
  }],
  verificationCount: Number,
  isPromoted: Boolean,
  promotedIncidentId: String  // PostgreSQL incident UUID
}
```

**Indexes**:
- `location: '2dsphere'` - Critical for geospatial queries

### PostgreSQL: Incident

```sql
CREATE TABLE incidents (
  id UUID PRIMARY KEY,
  title VARCHAR(500),
  description TEXT,
  location GEOGRAPHY(POINT, 4326),  -- PostGIS
  source incident_source,  -- 'community_promoted' | 'direct_report'
  community_post_id VARCHAR(50),  -- MongoDB reference
  verification_count INTEGER
);
```

## Configuration

### Environment Variables

```env
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=civicsync
POSTGRES_PASSWORD=your_password
POSTGRES_DB=civicsync

# MongoDB
MONGODB_URI=mongodb://localhost:27017/civicsync_community

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRATION=7d

# Geospatial
DEFAULT_SEARCH_RADIUS_METERS=2000
VERIFICATION_THRESHOLD=5
```

## User Roles

| Role | Permissions |
|------|-------------|
| `citizen` | Create posts, view feed |
| `volunteer` | All citizen + verify posts |
| `authority` | All volunteer + manage incidents |
| `admin` | Full access |

## WebSocket Events

Connect to: `ws://localhost:3000/events`

| Event | Description |
|-------|-------------|
| `newPost` | New post in your area |
| `postVerified` | Post received verification |
| `postPromoted` | Post promoted to incident |
| `incidentUpdate` | Incident status changed |

## Development

```bash
# Run tests
npm test

# Lint code
npm run lint

# Format code
npm run format
```

## Production Deployment

1. Set `NODE_ENV=production`
2. Use managed PostgreSQL with PostGIS
3. Use MongoDB Atlas or managed MongoDB
4. Set strong `JWT_SECRET`
5. Configure proper CORS origins
6. Enable SSL/TLS

## License

MIT
