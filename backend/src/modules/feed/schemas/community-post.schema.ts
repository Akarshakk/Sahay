import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

/**
 * GeoJSON Point subdocument for MongoDB geospatial queries
 * Follows GeoJSON specification: https://geojson.org/
 */
@Schema({ _id: false })
export class GeoPoint {
  @Prop({ type: String, enum: ['Point'], required: true, default: 'Point' })
  type: string;

  @Prop({
    type: [Number],
    required: true,
    validate: {
      validator: function (coords: number[]) {
        // [longitude, latitude] - longitude first!
        return (
          coords.length === 2 &&
          coords[0] >= -180 &&
          coords[0] <= 180 && // longitude
          coords[1] >= -90 &&
          coords[1] <= 90 // latitude
        );
      },
      message: 'Coordinates must be [longitude, latitude] with valid ranges',
    },
  })
  coordinates: number[]; // [longitude, latitude]
}

export const GeoPointSchema = SchemaFactory.createForClass(GeoPoint);

/**
 * Verification subdocument - tracks volunteer verifications
 */
@Schema({ _id: false })
export class Verification {
  @Prop({ required: true })
  odeclareId: string; // User ID from PostgreSQL

  @Prop({ required: true, default: Date.now })
  verifiedAt: Date;
}

export const VerificationSchema = SchemaFactory.createForClass(Verification);

/**
 * CommunityPost Schema - The "Tweet" for Community Pulse
 * 
 * This is stored in MongoDB with a 2dsphere index for geospatial queries.
 * Citizens post local issues, volunteers verify them, and posts with
 * >5 verifications are promoted to official incidents in PostgreSQL.
 */
@Schema({
  collection: 'community_posts',
  timestamps: true, // Adds createdAt and updatedAt automatically
})
export class CommunityPost {
  // MongoDB automatically creates _id, but we expose it
  _id: Types.ObjectId;

  @Prop({ required: true, minlength: 1, maxlength: 1000 })
  content: string;

  @Prop({
    required: true,
    enum: ['infrastructure', 'safety', 'sanitation', 'traffic', 'environment', 'other'],
    default: 'other',
  })
  category: string;

  /**
   * CRITICAL: GeoJSON Point for geospatial queries
   * This field has a 2dsphere index for $near and $geoWithin queries
   */
  @Prop({ type: GeoPointSchema, required: true, index: '2dsphere' })
  location: GeoPoint;

  @Prop()
  address: string;

  // Author information (references PostgreSQL user)
  @Prop({ required: true })
  authorId: string; // UUID from PostgreSQL users table

  @Prop({ required: true })
  authorName: string; // Cached for display without joins

  // Media attachments
  @Prop({ type: [String], default: [] })
  mediaUrls: string[];

  // Verification gamification
  @Prop({ type: [VerificationSchema], default: [] })
  verifications: Verification[];

  @Prop({ default: 0 })
  verificationCount: number;

  // Promotion tracking
  @Prop({ default: false })
  isPromoted: boolean;

  @Prop()
  promotedIncidentId: string; // UUID of incident in PostgreSQL

  @Prop()
  promotedAt: Date;

  // Soft delete
  @Prop({ default: true })
  isActive: boolean;

  // Timestamps (auto-managed by mongoose)
  createdAt: Date;
  updatedAt: Date;
}

export type CommunityPostDocument = CommunityPost & Document;

export const CommunityPostSchema = SchemaFactory.createForClass(CommunityPost);

/**
 * CRITICAL: Create 2dsphere index for geospatial queries
 * This enables $near, $geoWithin, and other geo operators
 */
CommunityPostSchema.index({ location: '2dsphere' });

// Compound indexes for common query patterns
CommunityPostSchema.index({ isActive: 1, createdAt: -1 });
CommunityPostSchema.index({ authorId: 1, createdAt: -1 });
CommunityPostSchema.index({ verificationCount: -1 });
CommunityPostSchema.index({ isPromoted: 1, isActive: 1 });
CommunityPostSchema.index({ category: 1, createdAt: -1 });

// Compound index: nearby + recent + active (most common query)
CommunityPostSchema.index({ isActive: 1, location: '2dsphere', createdAt: -1 });
