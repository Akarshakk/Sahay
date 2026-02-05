# Volunteer Task Management System - Implementation Guide

## Overview
This document describes the complete volunteer task management system for Sahay-AI, enabling authorities to create tasks and volunteers to complete them with photo proof and earn points.

## System Architecture

### Backend (NestJS + Firebase)

#### Database Models
- **Task**: Represents a task created by an authority
  - `id`: Unique task identifier
  - `title`: Task name
  - `description`: Detailed description
  - `region`: Geographic region (e.g., "Mumbai Central")
  - `areaId`: Area identifier for grouping
  - `createdBy`: Authority user ID
  - `assignedTo`: Array of volunteer IDs assigned to this task
  - `priority`: 'low' | 'medium' | 'high'
  - `status`: 'open' | 'in_progress' | 'completed' | 'verified'
  - `rewardPoints`: Points awarded for completion (10-1000)
  - `imageUrl`: Optional task banner/image
  - `deadline`: Optional deadline for task completion
  - `createdAt/updatedAt`: Timestamps

- **TaskSubmission**: Volunteer submission for task completion
  - `id`: Unique submission ID
  - `taskId`: Reference to parent task
  - `volunteerId`: Volunteer who submitted
  - `volunteerName`: Volunteer's name
  - `submissionImageUrl`: Photo proof URL
  - `submissionNotes`: Optional notes from volunteer
  - `status`: 'submitted' | 'verified' | 'rejected'
  - `verifiedBy`: Authority ID who verified
  - `verifiedAt`: Verification timestamp

#### API Endpoints

**Create Task** (Authority only)
```
POST /tasks
Body: {
  title: string,
  description: string,
  region: string,
  areaId: string,
  rewardPoints: number (10-1000),
  priority?: 'low' | 'medium' | 'high',
  imageUrl?: string,
  assignedTo?: string[],
  deadline?: ISO8601 string
}
```

**Get Tasks by Region** (Public)
```
GET /tasks/region/:region
Returns: Task[]
```

**Get Assigned Tasks** (Volunteer)
```
GET /tasks/assigned
Returns: Task[] - Only tasks assigned to current user
```

**Get Task Details** (Public)
```
GET /tasks/:taskId
Returns: Task
```

**Update Task** (Authority only)
```
PUT /tasks/:taskId
Body: Partial Task object
```

**Submit Task** (Volunteer)
```
POST /tasks/:taskId/submit
Body: {
  submissionImageUrl: string (URL of uploaded image),
  submissionNotes?: string
}
```

**Get Task Submissions** (Authority)
```
GET /tasks/:taskId/submissions
Returns: TaskSubmission[]
```

**Get Volunteer Submissions**
```
GET /tasks/volunteer/:volunteerId/submissions
Returns: TaskSubmission[]
GET /tasks/my/submissions (For current user)
Returns: TaskSubmission[]
```

**Verify Submission** (Authority only)
```
POST /tasks/submissions/:submissionId/verify
Body: {
  status: 'verified' | 'rejected',
  notes?: string
}
Action: Awards points to volunteer if verified
```

### Frontend (Flutter + Riverpod)

#### Data Models
Models are defined in `lib/core/models/task_model.dart` using `freezed` and `json_serializable` for automatic serialization.

#### Providers
- `getAssignedTasksProvider`: Fetch tasks assigned to current volunteer
- `getTasksByRegionProvider`: Fetch all tasks for a region
- `getTaskSubmissionsProvider`: Fetch submissions for a task
- `getMySubmissionsProvider`: Fetch current user's submissions
- `tasksProvider`: Notifier for task operations

#### Services
- `ApiService.createTask()`: Create new task
- `ApiService.getAssignedTasks()`: Fetch assigned tasks
- `ApiService.submitTask()`: Submit task completion with photo
- `ApiService.getTaskSubmissions()`: Get submissions for review
- `ApiService.verifySubmission()`: Verify submission and award points

### UI Screens

#### For Volunteers
1. **VolunteerTasksScreen** (`volunteer_tasks_detailed_screen.dart`)
   - Displays list of assigned tasks
   - Color-coded by priority (Red=High, Orange=Medium, Green=Low)
   - Task details including description, deadline, reward points
   - Submit button opens modal for photo upload and notes
   - Integration with image picker (camera + gallery)
   - Shows task status and completion indicators

2. **Task Submission Modal**
   - Camera/Gallery photo picker
   - Photo preview with ability to change
   - Optional notes field
   - Submit button with loading state

#### For Authority
1. **AuthorityCreateTaskScreen** (`create_task_screen.dart`)
   - Form to create new tasks
   - Title, description, reward points input
   - Priority level selector (Low/Medium/High)
   - Optional deadline picker
   - Automatic region/area population
   - Validation before submission

2. **AuthorityTaskVerificationScreen** (`task_verification_screen.dart`)
   - List of submissions for a task
   - Volunteer name, submission time, proof photo
   - Verify/Reject selector
   - Optional verification notes
   - Batch approval/rejection
   - Points awarded on verification

## Data Flow

### Task Creation Flow
```
Authority Create Task
  ↓
Authority Form Validation
  ↓
API Call: POST /tasks
  ↓
Firebase: Save to 'tasks' collection
  ↓
Return Task object with ID
  ↓
Update volunteer dashboard
```

### Task Submission Flow
```
Volunteer Views Task
  ↓
Click "Submit Task with Photo"
  ↓
Select/Take Photo
  ↓
Enter Optional Notes
  ↓
API Call: POST /tasks/:taskId/submit
  ↓
Firebase: Save TaskSubmission
  ↓
Update Task status to 'in_progress'
  ↓
Show Success Message
```

### Task Verification Flow
```
Authority Reviews Submissions
  ↓
Approve/Reject Selection
  ↓
Add Optional Notes
  ↓
API Call: POST /tasks/submissions/:submissionId/verify
  ↓
Firebase: Update TaskSubmission status
  ↓
If Verified: Award points to volunteer
  ↓
Update Task status to 'verified'
  ↓
Update volunteer reputation/points score
```

## Integration Points

### With Existing Systems

#### User System
- Uses JWT authentication from existing auth module
- Volunteers identified by `userId` and `role = 'volunteer'`
- Authorities identified by `role = 'authority'`

#### Points/Reputation System
- Award points on task verification
- Call existing `usersService.incrementVerificationCount()`
- Points stored in user profile

#### Location System
- Tasks assigned by region
- Uses existing region classification system
- Region data from user location

### Image Handling
Current implementation uses placeholder URLs. For production:
1. Integrate Firebase Storage for image upload
2. Generate signed URLs for uploaded images
3. Pass image URL to task submission endpoint
4. Delete old submissions' images on verification/rejection

## Testing Checklist

- [ ] Authority can create tasks with all fields
- [ ] Tasks appear in volunteer's assigned list
- [ ] Volunteer can submit task with photo
- [ ] Authority can view all submissions
- [ ] Authority can verify/reject submissions
- [ ] Points awarded correctly on verification
- [ ] Task status updates through workflow
- [ ] Images display correctly in submissions
- [ ] Deadline warnings show correctly
- [ ] Priority colors display correctly
- [ ] Form validation works properly
- [ ] Error handling and recovery

## Security Considerations

- ✅ Role-based access control (Authority/Volunteer)
- ✅ JWT authentication on all endpoints
- ✅ Only task creator can update task
- ✅ Only assigned volunteer can submit
- ✅ Only task creator can verify submissions
- ✅ Point awards tied to verified submissions
- ⚠️ Image upload validation needed
- ⚠️ File size limits to enforce
- ⚠️ Malware scanning for uploaded images

## Performance Optimization

- Use Firestore indexes for queries:
  - `tasks: (region, status, createdAt DESC)`
  - `task_submissions: (taskId, status)`
  - `task_submissions: (volunteerId, createdAt DESC)`
- Implement pagination for large task lists
- Cache task list client-side
- Lazy load images

## Future Enhancements

1. **Task Analytics**
   - Track completion rate by task type
   - Volunteer performance metrics
   - Authority task success rates

2. **Advanced Verification**
   - Photo quality analysis
   - AI-based proof verification
   - Multi-authority approval workflow

3. **Gamification**
   - Achievements/badges
   - Leaderboards
   - Streak tracking

4. **Task Scheduling**
   - Recurring tasks
   - Task templates
   - Bulk task creation

5. **Communication**
   - In-app notifications for new tasks
   - Comments on submissions
   - Authority feedback to volunteers

## Troubleshooting

### Tasks not showing up
- Check region matches user location
- Verify JWT token is valid
- Check task status (should be 'open' or 'in_progress')

### Points not awarded
- Verify submission status changed to 'verified'
- Check user exists in database
- Monitor `verifySubmission` API response

### Image upload fails
- Implement Firebase Storage integration
- Verify image permissions
- Check file size limits

### Performance issues
- Add Firestore indexes
- Implement pagination
- Use query limits
