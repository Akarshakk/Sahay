import { Injectable, NotFoundException, Logger, Inject } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { Incident } from './incident.interface';
import { CreateIncidentDto, UpdateIncidentDto, CreatePromotedIncidentDto } from './dto';
import { IncidentStatus, IncidentSource, IncidentPriority } from '../../common/enums';

@Injectable()
export class IncidentsService {
  private readonly logger = new Logger(IncidentsService.name);
  private db: admin.firestore.Firestore;
  private incidentsCollection: admin.firestore.CollectionReference;

  constructor(@Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App) {
    this.db = admin.firestore(this.firebaseApp);
    this.incidentsCollection = this.db.collection('incidents');
  }

  /**
   * Create a new incident (direct report)
   */
  async create(createIncidentDto: CreateIncidentDto, reporterId: string): Promise<Incident> {
    const incidentRef = this.incidentsCollection.doc();
    const now = new Date();

    const incident: Incident = {
      id: incidentRef.id,
      title: createIncidentDto.title,
      description: createIncidentDto.description,
      category: createIncidentDto.category,
      status: IncidentStatus.PENDING,
      priority: createIncidentDto.priority || IncidentPriority.MEDIUM,
      source: IncidentSource.DIRECT_REPORT,
      location: {
        latitude: createIncidentDto.latitude,
        longitude: createIncidentDto.longitude,
      },
      address: createIncidentDto.address,
      mediaUrls: createIncidentDto.mediaUrls,
      reporterId,
      verificationCount: 0,
      createdAt: now,
      updatedAt: now,
    };

    await incidentRef.set(incident);
    return incident;
  }

  /**
   * Create incident from promoted community post
   */
  async createFromCommunityPost(dto: CreatePromotedIncidentDto): Promise<Incident> {
    this.logger.log(`🎉 Promoting community post ${dto.communityPostId} to official incident`);

    const incidentRef = this.incidentsCollection.doc();
    const now = new Date();

    const incident: Incident = {
      id: incidentRef.id,
      title: dto.title,
      description: dto.description,
      category: dto.category,
      status: IncidentStatus.VERIFIED,
      priority: IncidentPriority.MEDIUM,
      source: IncidentSource.COMMUNITY_PROMOTED,
      location: {
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
      address: dto.address,
      mediaUrls: dto.mediaUrls,
      reporterId: dto.reporterId,
      communityPostId: dto.communityPostId,
      verificationCount: dto.verificationCount,
      promotedAt: now,
      createdAt: now,
      updatedAt: now,
    };

    await incidentRef.set(incident);
    this.logger.log(`✅ Created incident ${incident.id} from community post ${dto.communityPostId}`);
    return incident;
  }

  async findAll(
    page = 1,
    limit = 20,
    status?: IncidentStatus,
  ): Promise<{ data: Incident[]; total: number }> {
    let query: admin.firestore.Query = this.incidentsCollection;

    if (status) {
      query = query.where('status', '==', status);
    }

    query = query.orderBy('createdAt', 'desc').limit(limit).offset((page - 1) * limit);

    const snapshot = await query.get();
    const data = snapshot.docs.map((doc) => doc.data() as Incident);

    // Get total count (simplified - in production, use a counter document)
    let countQuery: admin.firestore.Query = this.incidentsCollection;
    if (status) {
      countQuery = countQuery.where('status', '==', status);
    }
    const countSnapshot = await countQuery.count().get();
    const total = countSnapshot.data().count;

    return { data, total };
  }

  async findById(id: string): Promise<Incident> {
    const doc = await this.incidentsCollection.doc(id).get();

    if (!doc.exists) {
      throw new NotFoundException(`Incident with ID ${id} not found`);
    }

    return doc.data() as Incident;
  }

  /**
   * Find incidents near a location
   * Note: Firestore doesn't have native geospatial queries like PostGIS.
   * For production, use Geohash-based queries or a separate geospatial index.
   * This is a simplified bounding box approach.
   */
  async findNearby(
    latitude: number,
    longitude: number,
    radiusMeters = 5000,
  ): Promise<Incident[]> {
    // Simple bounding box calculation (approximate)
    const latDelta = radiusMeters / 111320; // 1 degree latitude ≈ 111.32 km
    const lngDelta = radiusMeters / (111320 * Math.cos(latitude * (Math.PI / 180)));

    const snapshot = await this.incidentsCollection
      .where('location.latitude', '>=', latitude - latDelta)
      .where('location.latitude', '<=', latitude + latDelta)
      .orderBy('location.latitude')
      .get();

    // Filter by longitude in memory (Firestore limitation)
    const incidents = snapshot.docs
      .map((doc) => doc.data() as Incident)
      .filter(
        (incident) =>
          incident.location.longitude >= longitude - lngDelta &&
          incident.location.longitude <= longitude + lngDelta,
      );

    return incidents;
  }

  async update(id: string, updateIncidentDto: UpdateIncidentDto): Promise<Incident> {
    const incidentRef = this.incidentsCollection.doc(id);
    const doc = await incidentRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`Incident with ID ${id} not found`);
    }

    const updateData: any = {
      ...updateIncidentDto,
      updatedAt: new Date(),
    };

    if (updateIncidentDto.status === IncidentStatus.RESOLVED) {
      updateData.resolvedAt = new Date();
    }

    await incidentRef.update(updateData);
    return this.findById(id);
  }

  async assignToAuthority(incidentId: string, authorityId: string): Promise<Incident> {
    const incidentRef = this.incidentsCollection.doc(incidentId);
    const doc = await incidentRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`Incident with ID ${incidentId} not found`);
    }

    await incidentRef.update({
      assignedAuthorityId: authorityId,
      status: IncidentStatus.IN_PROGRESS,
      updatedAt: new Date(),
    });

    return this.findById(incidentId);
  }
}
