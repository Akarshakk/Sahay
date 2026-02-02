import { Module } from '@nestjs/common';
import { SOSController } from './sos.controller';
import { SOSService } from './sos.service';
import { UsersModule } from '../users/users.module';

@Module({
    imports: [UsersModule],
    controllers: [SOSController],
    providers: [SOSService],
    exports: [SOSService],
})
export class SOSModule { }
