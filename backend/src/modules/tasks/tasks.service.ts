import { Injectable, NotFoundException, ForbiddenException, Inject } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { Task, TaskSubmission } from './task.interface';
import { CreateTaskDto, UpdateTaskDto, SubmitTaskDto, VerifyTaskDto } from './dto';

@Injectable()
export class TasksService {
  private db: admin.firestore.Firestore;
  private tasksCollection: admin.firestore.CollectionReference;
  private submissionsCollection: admin.firestore.CollectionReference;

  constructor(@Inject(FIREBASE_APP) firebaseApp: admin.app.App) {
    this.db = admin.firestore(firebaseApp);
    this.tasksCollection = this.db.collection('tasks');
    this.submissionsCollection = this.db.collection('task_submissions');
  }

  // Create a new task (Authority only)
  async create(createTaskDto: CreateTaskDto, authorityId: string): Promise<Task> {
    const taskRef = this.tasksCollection.doc();
    const now = new Date();

    const task: Task = {
      id: taskRef.id,
      title: createTaskDto.title,
      description: createTaskDto.description,
      region: createTaskDto.region,
      areaId: createTaskDto.areaId,
      createdBy: authorityId,
      assignedTo: createTaskDto.assignedTo || [],
      priority: createTaskDto.priority || 'medium',
      status: 'open',
      rewardPoints: createTaskDto.rewardPoints || 0,
      imageUrl: createTaskDto.imageUrl || null,
      deadline: createTaskDto.deadline ? new Date(createTaskDto.deadline) : null,
      createdAt: now,
      updatedAt: now,
    };

    await taskRef.set(task);
    return task;
  }

  // Get all tasks for a region
  async getTasksByRegion(region: string): Promise<Task[]> {
    // Note: avoid complex Firestore composite index requirements by
    // querying by region only and filtering statuses in memory.
    const snapshot = await this.tasksCollection
      .where('region', '==', region)
      .get();

    const tasks = snapshot.docs.map(doc => doc.data() as Task);

    return tasks
      .filter(task => ['open', 'in_progress'].includes(task.status))
      .sort(
        (a, b) =>
          new Date((b.createdAt as unknown as Date)).getTime() -
          new Date((a.createdAt as unknown as Date)).getTime(),
      );
  }

  // Get task by ID
  async getById(taskId: string): Promise<Task> {
    const doc = await this.tasksCollection.doc(taskId).get();
    if (!doc.exists) {
      throw new NotFoundException(`Task with ID ${taskId} not found`);
    }
    return doc.data() as Task;
  }

  // Get tasks assigned to a volunteer
  async getAssignedToVolunteer(volunteerId: string): Promise<Task[]> {
    // To reduce chances of Firestore index-related failures, avoid
    // combining array-contains with orderBy and instead sort in memory.
    const snapshot = await this.tasksCollection
      .where('assignedTo', 'array-contains', volunteerId)
      .get();

    const tasks = snapshot.docs.map(doc => doc.data() as Task);

    return tasks.sort(
      (a, b) =>
        new Date((b.createdAt as unknown as Date)).getTime() -
        new Date((a.createdAt as unknown as Date)).getTime(),
    );
  }

  // Update task (Authority only)
  async update(taskId: string, updateTaskDto: UpdateTaskDto, authorityId: string): Promise<Task> {
    const taskRef = this.tasksCollection.doc(taskId);
    const doc = await taskRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`Task with ID ${taskId} not found`);
    }

    const task = doc.data() as Task;
    if (task.createdBy !== authorityId) {
      throw new ForbiddenException('Only the authority who created this task can update it');
    }

    const updateData = {
      ...updateTaskDto,
      updatedAt: new Date(),
    };

    await taskRef.update(updateData);
    return this.getById(taskId);
  }

  // Get tasks created by an authority (for CRUD dashboard)
  async getTasksForAuthority(authorityId: string): Promise<Task[]> {
    const snapshot = await this.tasksCollection
      .where('createdBy', '==', authorityId)
      .get();

    const tasks = snapshot.docs.map(doc => doc.data() as Task);

    return tasks.sort(
      (a, b) =>
        new Date((b.createdAt as unknown as Date)).getTime() -
        new Date((a.createdAt as unknown as Date)).getTime(),
    );
  }

  // Delete a task and its submissions (Authority only)
  async delete(taskId: string, authorityId: string): Promise<void> {
    const taskRef = this.tasksCollection.doc(taskId);
    const doc = await taskRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`Task with ID ${taskId} not found`);
    }

    const task = doc.data() as Task;
    if (task.createdBy !== authorityId) {
      throw new ForbiddenException('Only the authority who created this task can delete it');
    }

    // Delete all submissions for this task in a batch, then the task itself
    const submissionsSnapshot = await this.submissionsCollection
      .where('taskId', '==', taskId)
      .get();

    const batch = this.db.batch();

    submissionsSnapshot.docs.forEach(submissionDoc => {
      batch.delete(submissionDoc.ref);
    });

    batch.delete(taskRef);

    await batch.commit();
  }

  // Volunteer submits task completion with photo
  async submitTask(submitTaskDto: SubmitTaskDto, volunteerId: string, volunteerName: string): Promise<TaskSubmission> {
    const task = await this.getById(submitTaskDto.taskId);

    // Check if task is restricted to specific volunteers
    if (task.assignedTo && task.assignedTo.length > 0 && !task.assignedTo.includes(volunteerId)) {
      console.warn(`[WARN] Volunteer ${volunteerId} denied submission for restricted task ${task.id}`);
      throw new ForbiddenException('You are not assigned to this task');
    }
    console.log(`[DEBUG] Volunteer ${volunteerId} submitting task ${task.id}`);

    const submissionRef = this.submissionsCollection.doc();
    const now = new Date();

    const submission: TaskSubmission = {
      id: submissionRef.id,
      taskId: submitTaskDto.taskId,
      volunteerId,
      volunteerName,
      submissionImageUrl: submitTaskDto.submissionImageUrl,
      ...(submitTaskDto.submissionNotes ? { submissionNotes: submitTaskDto.submissionNotes } : {}),
      status: 'submitted',
      createdAt: now,
      updatedAt: now,
    };

    await submissionRef.set(submission);

    // Update task status to in_progress
    await this.tasksCollection.doc(submitTaskDto.taskId).update({
      status: 'in_progress',
      updatedAt: new Date(),
    });

    return submission;
  }

  // Get submissions for a task
  async getSubmissionsForTask(taskId: string): Promise<TaskSubmission[]> {
    try {
      console.log(`[DEBUG] fetching submissions for task ${taskId}`);
      const snapshot = await this.submissionsCollection
        .where('taskId', '==', taskId)
        .get(); // Removing orderBy to avoid index requirement

      const submissions = snapshot.docs.map(doc => doc.data() as TaskSubmission);
      // Sort in memory
      return submissions.sort((a, b) => {
        const timeA = a.createdAt instanceof Date ? a.createdAt.getTime() : new Date(a.createdAt).getTime();
        const timeB = b.createdAt instanceof Date ? b.createdAt.getTime() : new Date(b.createdAt).getTime();
        return timeB - timeA;
      });
    } catch (error) {
      console.error(`[ERROR] getSubmissionsForTask failed for ${taskId}:`, error);
      throw error;
    }
  }

  // Get submissions for a volunteer
  async getSubmissionsForVolunteer(volunteerId: string): Promise<TaskSubmission[]> {
    try {
      console.log(`[DEBUG] fetching submissions for volunteer ${volunteerId}`);
      if (!volunteerId) {
        console.warn('[WARN] No volunteerId provided to getSubmissionsForVolunteer');
        return [];
      }
      const snapshot = await this.submissionsCollection
        .where('volunteerId', '==', volunteerId)
        .get(); // Removing orderBy to avoid index requirement

      const submissions = snapshot.docs.map(doc => doc.data() as TaskSubmission);
      // Sort in memory
      return submissions.sort((a, b) => {
        const timeA = a.createdAt instanceof Date ? a.createdAt.getTime() : new Date(a.createdAt).getTime();
        const timeB = b.createdAt instanceof Date ? b.createdAt.getTime() : new Date(b.createdAt).getTime();
        return timeB - timeA;
      });
    } catch (error) {
      console.error(`[ERROR] getSubmissionsForVolunteer failed for ${volunteerId}:`, error);
      throw error;
    }
  }

  // Authority verifies task submission and awards points
  async verifySubmission(
    verifyTaskDto: VerifyTaskDto,
    authorityId: string,
    usersService: any, // Injected from controller
  ): Promise<TaskSubmission> {
    const submissionRef = this.submissionsCollection.doc(verifyTaskDto.submissionId);
    const submissionDoc = await submissionRef.get();

    if (!submissionDoc.exists) {
      throw new NotFoundException(`Submission with ID ${verifyTaskDto.submissionId} not found`);
    }

    const submission = submissionDoc.data() as TaskSubmission;
    const task = await this.getById(submission.taskId);

    if (task.createdBy !== authorityId) {
      throw new ForbiddenException('Only the authority who created this task can verify submissions');
    }

    const updateData = {
      status: verifyTaskDto.status,
      verifiedBy: authorityId,
      verifiedAt: new Date(),
      updatedAt: new Date(),
    };

    await submissionRef.update(updateData);

    // If verified, award points to volunteer
    if (verifyTaskDto.status === 'verified') {
      const volunteer = await usersService.findById(submission.volunteerId);
      await usersService.incrementVerificationCount(submission.volunteerId);

      // Award bonus points for task completion
      await this.tasksCollection.doc(submission.taskId).update({
        status: 'verified',
        updatedAt: new Date(),
      });
    }

    return this.getSubmissionById(verifyTaskDto.submissionId);
  }

  // Get submission by ID
  async getSubmissionById(submissionId: string): Promise<TaskSubmission> {
    const doc = await this.submissionsCollection.doc(submissionId).get();
    if (!doc.exists) {
      throw new NotFoundException(`Submission with ID ${submissionId} not found`);
    }
    return doc.data() as TaskSubmission;
  }
}
