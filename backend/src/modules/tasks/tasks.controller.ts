import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../../common/enums';
import { TasksService } from './tasks.service';
import { UsersService } from '../users/users.service';
import { CreateTaskDto, UpdateTaskDto, SubmitTaskDto, VerifyTaskDto } from './dto';
import { Task, TaskSubmission } from './task.interface';

@ApiTags('Tasks')
@Controller('tasks')
export class TasksController {
  constructor(
    private readonly tasksService: TasksService,
    private readonly usersService: UsersService,
  ) { }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHORITY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new task (Authority only)' })
  @ApiResponse({ status: 201, description: 'Task created successfully' })
  async create(@Request() req: any, @Body() createTaskDto: CreateTaskDto): Promise<Task> {
    const user = req.user;
    if (!user || user.role !== UserRole.AUTHORITY) {
      throw new BadRequestException('Only authorities can create tasks');
    }

    return this.tasksService.create(createTaskDto, user.id)
  }

  @Get('region/:region')
  @ApiOperation({ summary: 'Get all open tasks for a region' })
  @ApiResponse({ status: 200, description: 'Tasks retrieved successfully' })
  async getByRegion(@Param('region') region: string): Promise<Task[]> {
    return this.tasksService.getTasksByRegion(region);
  }

  @Get('assigned')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get tasks assigned to current volunteer' })
  @ApiResponse({ status: 200, description: 'Assigned tasks retrieved' })
  async getAssigned(@Request() req: any): Promise<Task[]> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    return this.tasksService.getAssignedToVolunteer(user.id)
  }

  @Get('my')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get tasks created by current authority' })
  @ApiResponse({ status: 200, description: 'Authority tasks retrieved' })
  async getMyTasks(@Request() req: any): Promise<Task[]> {
    console.log('DEBUG /tasks/my: req.user =', req.user);
    console.log('DEBUG /tasks/my: headers =', req.headers?.authorization?.substring(0, 50));
    const user = req.user;
    if (!user) {
      console.log('DEBUG /tasks/my: User not authenticated!');
      throw new BadRequestException('User not authenticated');
    }

    console.log('DEBUG /tasks/my: User role =', user.role);
    // Allow authority users to see their created tasks
    if (user.role !== 'authority' && user.role !== UserRole.AUTHORITY) {
      throw new BadRequestException('Only authorities can access their tasks');
    }

    return this.tasksService.getTasksForAuthority(user.id);
  }

  @Get('my/submissions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user submissions' })
  @ApiResponse({ status: 200, description: 'Submissions retrieved' })
  async getMySubmissions(@Request() req: any): Promise<TaskSubmission[]> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    return this.tasksService.getSubmissionsForVolunteer(user.id);
  }

  @Get(':taskId')
  @ApiOperation({ summary: 'Get task details by ID' })
  @ApiResponse({ status: 200, description: 'Task retrieved successfully' })
  async getById(@Param('taskId') taskId: string): Promise<Task> {
    return this.tasksService.getById(taskId);
  }

  @Put(':taskId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHORITY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a task (Authority only)' })
  @ApiResponse({ status: 200, description: 'Task updated successfully' })
  async update(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Body() updateTaskDto: UpdateTaskDto,
  ): Promise<Task> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    return this.tasksService.update(taskId, updateTaskDto, user.id);
  }

  @Delete(':taskId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHORITY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a task (Authority only)' })
  @ApiResponse({ status: 200, description: 'Task deleted successfully' })
  async delete(
    @Request() req: any,
    @Param('taskId') taskId: string,
  ): Promise<{ success: boolean }> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    await this.tasksService.delete(taskId, user.id);
    return { success: true };
  }

  @Post(':taskId/submit')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Volunteer submits task completion with photo' })
  @ApiResponse({ status: 201, description: 'Task submission created' })
  async submitTask(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Body() submitTaskDto: SubmitTaskDto,
  ): Promise<TaskSubmission> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    const submitData = {
      ...submitTaskDto,
      taskId, // Use taskId from URL param
    };

    return this.tasksService.submitTask(submitData, user.id, user.name || user.email)
  }

  @Get(':taskId/submissions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all submissions for a task' })
  @ApiResponse({ status: 200, description: 'Submissions retrieved' })
  async getTaskSubmissions(@Param('taskId') taskId: string): Promise<TaskSubmission[]> {
    return this.tasksService.getSubmissionsForTask(taskId);
  }

  @Get('volunteer/:volunteerId/submissions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all submissions from a volunteer' })
  @ApiResponse({ status: 200, description: 'Submissions retrieved' })
  async getVolunteerSubmissions(@Param('volunteerId') volunteerId: string): Promise<TaskSubmission[]> {
    return this.tasksService.getSubmissionsForVolunteer(volunteerId);
  }

  @Post('submissions/:submissionId/verify')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHORITY)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Authority verifies task submission' })
  @ApiResponse({ status: 200, description: 'Submission verified' })
  async verifySubmission(
    @Request() req: any,
    @Param('submissionId') submissionId: string,
    @Body() verifyTaskDto: VerifyTaskDto,
  ): Promise<TaskSubmission> {
    const user = req.user;
    if (!user) {
      throw new BadRequestException('User not authenticated');
    }

    const verifyData = {
      ...verifyTaskDto,
      submissionId, // Use submissionId from URL param
    };

    return this.tasksService.verifySubmission(verifyData, user.id, this.usersService)
  }

}
