import { Module } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { UsersModule } from '../users/users.module';
import { firebaseProvider } from '../../firebase';

@Module({
  imports: [UsersModule],
  controllers: [TasksController],
  providers: [TasksService, firebaseProvider],
  exports: [TasksService],
})
export class TasksModule {}
