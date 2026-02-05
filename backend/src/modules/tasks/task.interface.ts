export interface Task {
  id: string;
  title: string;
  description: string;
  region: string;
  areaId: string;
  createdBy: string; // Authority ID
  assignedTo?: string[]; // Array of volunteer IDs
  priority: 'low' | 'medium' | 'high';
  status: 'open' | 'in_progress' | 'completed' | 'verified';
  rewardPoints: number;
  deadline?: Date | null;
  imageUrl?: string | null; // Optional task image/banner
  createdAt: Date;
  updatedAt: Date;
}

export interface TaskSubmission {
  id: string;
  taskId: string;
  volunteerId: string;
  volunteerName: string;
  submissionImageUrl: string; // Photo uploaded by volunteer
  submissionNotes?: string;
  status: 'submitted' | 'verified' | 'rejected';
  verifiedBy?: string; // Authority ID who verified
  verifiedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
