import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { IncidentStatus, IncidentPriority, IncidentSource } from '../../common/enums';
import { User } from '../users/user.entity';

@Entity('incidents')
export class Incident {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 500 })
  title: string;

  @Column('text')
  description: string;

  @Column({ length: 100 })
  category: string;

  @Column({
    type: 'enum',
    enum: IncidentStatus,
    default: IncidentStatus.PENDING,
  })
  status: IncidentStatus;

  @Column({
    type: 'enum',
    enum: IncidentPriority,
    default: IncidentPriority.MEDIUM,
  })
  priority: IncidentPriority;

  @Column({
    type: 'enum',
    enum: IncidentSource,
    default: IncidentSource.DIRECT_REPORT,
  })
  source: IncidentSource;

  // PostGIS Geography type for geospatial queries
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  location: string;

  @Column({ length: 500, nullable: true })
  address: string;

  @Column('text', { array: true, nullable: true, name: 'media_urls' })
  mediaUrls: string[];

  // Reference to MongoDB Community Post (if promoted)
  @Column({ name: 'community_post_id', nullable: true, length: 50 })
  communityPostId: string;

  @Column({ name: 'verification_count', default: 0 })
  verificationCount: number;

  @Column({ name: 'promoted_at', nullable: true })
  promotedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.reportedIncidents, { nullable: true })
  @JoinColumn({ name: 'reporter_id' })
  reporter: User;

  @Column({ name: 'reporter_id', nullable: true })
  reporterId: string;

  @ManyToOne(() => User, (user) => user.assignedIncidents, { nullable: true })
  @JoinColumn({ name: 'assigned_authority_id' })
  assignedAuthority: User;

  @Column({ name: 'assigned_authority_id', nullable: true })
  assignedAuthorityId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @Column({ name: 'resolved_at', nullable: true })
  resolvedAt: Date;
}
