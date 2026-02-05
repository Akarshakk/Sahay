import { Module, forwardRef } from '@nestjs/common';
import { SOSController } from './sos.controller';
import { SOSService } from './sos.service';
import { UsersModule } from '../users/users.module';
import { WebsocketModule } from '../websocket/websocket.module';

@Module({
    imports: [UsersModule, forwardRef(() => WebsocketModule)],
    controllers: [SOSController],
    providers: [SOSService],
    exports: [SOSService],
})
export class SOSModule { }
