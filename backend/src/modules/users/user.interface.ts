// User interface for Firestore (replaces TypeORM entity)
import { UserRole } from '../../common/enums';

export interface User {
    id: string;
    email: string;
    passwordHash: string;
    fullName: string;
    phone?: string | null;
    role: UserRole;
    avatarUrl?: string | null;
    profession?: string | null;          // User's profession
    address?: string | null;             // User's home address
    dob?: string | null;                 // Date of birth

    // Location fields
    state?: string | null;               // State name
    district?: string | null;            // District name
    city?: string | null;                // City name

    // Area-based assignment (for volunteers/authorities)
    registeredArea?: string | null;      // Area name like "Mumbai Central"
    registeredAreaId?: string | null;    // Area ID for Firestore queries

    // Identity document
    identityDocumentUrl?: string | null;
    identityDocumentType?: 'aadhaar' | 'pan' | 'driving_license' | 'voter_id' | null;

    // Authority-specific fields
    authorityCode?: string | null;       // Code used during registration
    department?: string | null;          // Police, Fire, Hospital, etc.
    registrationNumber?: string | null;  // Government registration number

    // Verification status
    phoneVerified: boolean;
    isVerified: boolean;
    isActive: boolean;
    verificationCount: number;
    reputationScore: number;

    lastKnownLocation?: {
        latitude: number;
        longitude: number;
    };

    // Emergency Contacts
    emergencyContacts?: {
        name: string;
        phone: string;
        relation: string;
    }[];

    createdAt: Date;
    updatedAt: Date;
}
