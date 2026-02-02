// Community Post interface for Firestore (replaces Mongoose schema)
export interface CommunityPost {
    id: string;
    content: string;
    category: string;
    location: {
        latitude: number;
        longitude: number;
    };
    address?: string;
    authorId: string;
    authorName: string;
    mediaUrls: string[];
    verifications: {
        odeclareId: string;
        verifiedAt: Date;
    }[];
    verificationCount: number;
    isPromoted: boolean;
    promotedIncidentId?: string;
    promotedAt?: Date;
    isActive: boolean;
    likes: string[]; // Array of user IDs
    commentsCount: number;
    createdAt: Date;
    updatedAt: Date;
}

// Chat Message interface for Firestore (replaces Mongoose schema)
export interface ChatMessage {
    id: string;
    postId: string;
    authorId: string;
    authorName: string;
    message: string;
    replyToMessageId?: string;
    reactions: string[];
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
