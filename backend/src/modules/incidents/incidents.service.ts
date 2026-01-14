import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Incident } from './incident.entity';
import { CreateIncidentDto, UpdateIncidentDto, CreatePromotedIncidentDto } from './dto';
import { IncidentStatus, IncidentSource } from '../../common/enums';

@Injectable()
export class IncidentsService {
  private readonly logger = new Logger(IncidentsService.name);

  constructor(
    @InjectRepository(Incident)
    private readonly incidentRepository: Repository<Incident>,
  ) {}

  /**
   * Create a new incident (direct report)
   */
  async create(createIncidentDto: CreateIncidentDto, reporterId: string): Promise<Incident> {
    const incident = this.incidentRepository.create({
      ...createIncidentDto,
      reporterId,
      // Convert lat/lng to PostGIS Point format
      location: `POINT(${createIncidentDto.longitude} ${createIncidentDto.latitude})`,
      source: IncidentSource.DIRECT_REPORT,
    });

    return this.incidentRepository.save(incident);
  }

  /**
   * Create incident from promoted community post
   * This is called when a community post reaches verification threshold
   */
  async createFromCommunityPost(dto: CreatePromotedIncidentDto): Promise<Incident> {
    this.logger.log(`🎉 Promoting community post ${dto.communityPostId} to official incident`);

    const incident = this.incidentRepository.create({
      title: dto.title,
      description: dto.description,
      category: dto.category,
      location: `POINT(${dto.longitude} ${dto.latitude})`,
      address: dto.address,
      mediaUrls: dto.mediaUrls,
      reporterId: dto.reporterId,
      communityPostId: dto.communityPostId,
      verificationCount: dto.verificationCount,
      source: IncidentSource.COMMUNITY_PROMOTED,
      promotedAt: new Date(),
      status: IncidentStatus.VERIFIED, // Auto-verified since community validated
    });

    const savedIncident = await this.incidentRepository.save(incident);
    
    this.logger.log(`✅ Created incident ${savedIncident.id} from community post ${dto.communityPostId}`);
    
    return savedIncident;
  }

  async findAll(
    page = 1,
    limit = 20,
    status?: IncidentStatus,
  ): Promise<{ data: Incident[]; total: number }> {
    const query = this.incidentRepository.createQueryBuilder('incident');

    if (status) {
      query.where('incident.status = :status', { status });
    }

    query
      .orderBy('incident.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    const [data, total] = await query.getManyAndCount();

    return { data, total };
  }

  async findById(id: string): Promise<Incident> {
    const incident = await this.incidentRepository.findOne({
      where: { id },
      relations: ['reporter', 'assignedAuthority'],
    });

    if (!incident) {
      throw new NotFoundException(`Incident with ID ${id} not found`);
    }

    return incident;
  }

  /**
   * Find incidents near a location using PostGIS
   */
  async findNearby(
    latitude: number,
    longitude: number,
    radiusMeters = 5000,
  ): Promise<Incident[]> {
    return this.incidentRepository
      .createQueryBuilder('incident')
      .where(
        `ST_DWithin(
          incident.location,
          ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography,
          :radius
        )`,
        { latitude, longitude, radius: radiusMeters },
      )
      .orderBy('incident.createdAt', 'DESC')
      .getMany();
  }

  async update(id: string, updateIncidentDto: UpdateIncidentDto): Promise<Incident> {
    const incident = await this.findById(id);
    
    Object.assign(incident, updateIncidentDto);

    if (updateIncidentDto.status === IncidentStatus.RESOLVED) {
      incident.resolvedAt = new Date();
    }

    return this.incidentRepository.save(incident);
  }

  async assignToAuthority(incidentId: string, authorityId: string): Promise<Incident> {
    const incident = await this.findById(incidentId);
    incident.assignedAuthorityId = authorityId;
    incident.status = IncidentStatus.IN_PROGRESS;
    return this.incidentRepository.save(incident);
  }
}
