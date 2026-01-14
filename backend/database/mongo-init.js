// MongoDB Initialization Script for Community Pulse
// This creates the collection with proper geospatial indexes

db = db.getSiblingDB('civicsync_community');

// Create the community_posts collection with schema validation
db.createCollection('community_posts', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['content', 'location', 'authorId', 'createdAt'],
      properties: {
        content: {
          bsonType: 'string',
          minLength: 1,
          maxLength: 1000,
          description: 'Post content - required string between 1-1000 chars'
        },
        category: {
          bsonType: 'string',
          enum: ['infrastructure', 'safety', 'sanitation', 'traffic', 'environment', 'other'],
          description: 'Category of the issue'
        },
        location: {
          bsonType: 'object',
          required: ['type', 'coordinates'],
          properties: {
            type: {
              bsonType: 'string',
              enum: ['Point'],
              description: 'GeoJSON type - must be Point'
            },
            coordinates: {
              bsonType: 'array',
              minItems: 2,
              maxItems: 2,
              items: { bsonType: 'double' },
              description: 'Coordinates [longitude, latitude]'
            }
          }
        },
        address: {
          bsonType: 'string',
          description: 'Human-readable address'
        },
        authorId: {
          bsonType: 'string',
          description: 'UUID of the author from PostgreSQL users table'
        },
        authorName: {
          bsonType: 'string',
          description: 'Cached author name for display'
        },
        mediaUrls: {
          bsonType: 'array',
          items: { bsonType: 'string' },
          description: 'Array of media URLs'
        },
        verifications: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              odeclareId: { bsonType: 'string' },
              verifiedAt: { bsonType: 'date' }
            }
          },
          description: 'Array of volunteer verifications'
        },
        verificationCount: {
          bsonType: 'int',
          minimum: 0,
          description: 'Count of verifications'
        },
        isPromoted: {
          bsonType: 'bool',
          description: 'Whether promoted to official incident'
        },
        promotedIncidentId: {
          bsonType: 'string',
          description: 'UUID of promoted incident in PostgreSQL'
        },
        promotedAt: {
          bsonType: 'date',
          description: 'When the post was promoted'
        },
        isActive: {
          bsonType: 'bool',
          description: 'Soft delete flag'
        },
        createdAt: {
          bsonType: 'date',
          description: 'Creation timestamp'
        },
        updatedAt: {
          bsonType: 'date',
          description: 'Last update timestamp'
        }
      }
    }
  },
  validationLevel: 'moderate',
  validationAction: 'warn'
});

// CRITICAL: Create 2dsphere index for geospatial queries
// This enables $near and $geoWithin queries for the 2km radius feature
db.community_posts.createIndex(
  { location: '2dsphere' },
  { 
    name: 'idx_location_2dsphere',
    background: true 
  }
);

// Additional indexes for query performance
db.community_posts.createIndex(
  { createdAt: -1 },
  { name: 'idx_created_at_desc' }
);

db.community_posts.createIndex(
  { authorId: 1 },
  { name: 'idx_author_id' }
);

db.community_posts.createIndex(
  { verificationCount: -1 },
  { name: 'idx_verification_count' }
);

db.community_posts.createIndex(
  { isPromoted: 1, isActive: 1 },
  { name: 'idx_promoted_active' }
);

db.community_posts.createIndex(
  { category: 1, createdAt: -1 },
  { name: 'idx_category_created' }
);

// Compound index for common query pattern: nearby + recent + active
db.community_posts.createIndex(
  { isActive: 1, location: '2dsphere', createdAt: -1 },
  { name: 'idx_active_location_created' }
);

print('✅ CivicSync MongoDB initialized with geospatial indexes');
print('📍 2dsphere index created on location field for radius queries');
