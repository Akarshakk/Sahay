// User interface for Firestore (replaces TypeORM entity)
import { UserRole } from '../../common/enums';

export interface User {
    id: string;
    email: string;
    passwordHash: string;
    fullName: string;
    phone?: string;
    role: UserRole;
    avatarUrl?: string;
    isVerified: boolean;
    isActive: boolean;
    verificationCount: number;
    reputationScore: number;
    lastKnownLocation?: {
        latitude: number;
        longitude: number;
    };
    createdAt: Date;
    updatedAt: Date;
}
