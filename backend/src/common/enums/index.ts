export enum UserRole {
  CITIZEN = 'citizen',
  VOLUNTEER = 'volunteer',
  AUTHORITY = 'authority',
  ADMIN = 'admin',
}

export enum IncidentStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  IN_PROGRESS = 'in_progress',
  RESOLVED = 'resolved',
  CLOSED = 'closed',
}

export enum IncidentPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export enum IncidentSource {
  DIRECT_REPORT = 'direct_report',
  COMMUNITY_PROMOTED = 'community_promoted',
  AUTHORITY_CREATED = 'authority_created',
}

export enum PostCategory {
  INFRASTRUCTURE = 'infrastructure',
  SAFETY = 'safety',
  SANITATION = 'sanitation',
  TRAFFIC = 'traffic',
  ENVIRONMENT = 'environment',
  OTHER = 'other',
}
