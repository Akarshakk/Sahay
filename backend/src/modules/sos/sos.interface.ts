// Volunteer response tracking
export interface VolunteerResponse {
    odableId: string;
    odableName: string;
    respondedAt: Date;
    status: 'ON_THE_WAY' | 'ARRIVED' | 'CANCELLED';
    location?: {
        latitude: number;
        longitude: number;
    };
    distanceKm?: number;
}

// Resource dispatched by authority
export interface DispatchedResource {
    resourceId: string;
    resourceName: string;
    quantity: number;
    category: string;
}

// Authority dispatch tracking
export interface AuthorityDispatch {
    authorityId: string;
    authorityName: string;
    department?: string;
    dispatchedAt: Date;
    resources: DispatchedResource[];
    status: 'DISPATCHED' | 'EN_ROUTE' | 'ARRIVED' | 'COMPLETED';
}

export interface SOSLog {
    id: string;
    userId: string;
    userName: string;
    userPhone: string;
    type: 'POLICE' | 'AMBULANCE' | 'FIRE' | 'CONTACTS' | 'Custom';
    status: 'TRIGGERED' | 'RESOLVED' | 'FALSE_ALARM';
    location: {
        latitude: number;
        longitude: number;
    };
    address?: string;
    message?: string;
    batteryLevel?: number;
    actions: {
        timestamp: Date;
        action: string; // "Call 100", "SMS Sent", "Siren Started"
        details?: string;
    }[];
    // New fields for tracking responses
    respondingVolunteers?: VolunteerResponse[];
    authorityDispatches?: AuthorityDispatch[];
    createdAt: Date;
}
