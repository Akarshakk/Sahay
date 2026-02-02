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
    batteryLevel?: number;
    actions: {
        timestamp: Date;
        action: string; // "Call 100", "SMS Sent", "Siren Started"
        details?: string;
    }[];
    createdAt: Date;
}
