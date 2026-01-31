// Incident interface for Firestore (replaces TypeORM entity)
import { IncidentStatus, IncidentPriority, IncidentSource } from '../../common/enums';

export interface Incident {
    id: string;
    title: string;
    description: string;
    category: string;
    status: IncidentStatus;
    priority: IncidentPriority;
    source: IncidentSource;
    location: {
        latitude: number;
        longitude: number;
    };
    address?: string;
    mediaUrls?: string[];
    communityPostId?: string;
    verificationCount: number;
    promotedAt?: Date;
    reporterId?: string;
    assignedAuthorityId?: string;
    createdAt: Date;
    updatedAt: Date;
    resolvedAt?: Date;
}
