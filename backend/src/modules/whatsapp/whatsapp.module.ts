/**
 * WhatsApp Chatbot Module
 * 
 * ISOLATED MODULE - Does not modify any existing code
 * 
 * This module provides WhatsApp chatbot functionality via Twilio webhook.
 * It integrates with existing services (Incidents, SOS, Users) through dependency injection.
 * 
 * Setup:
 * 1. Create Twilio account: https://twilio.com
 * 2. Enable WhatsApp Sandbox in Twilio Console
 * 3. Set webhook URL to: https://your-domain.com/api/v1/webhook/whatsapp
 * 4. For local testing, use ngrok: ngrok http 3000
 */

import { Module } from '@nestjs/common';
import { WhatsAppController } from './whatsapp.controller';
import { WhatsAppService } from './whatsapp.service';

// Import required modules for service dependencies
import { IncidentsModule } from '../incidents/incidents.module';
import { WebsocketModule } from '../websocket/websocket.module';
import { SOSModule } from '../sos/sos.module';
import { UsersModule } from '../users/users.module';

@Module({
    imports: [
        // Import existing modules to access their services
        IncidentsModule,
        WebsocketModule,
        SOSModule,      // For SOS functionality
        UsersModule,    // For user lookup and emergency contacts
    ],
    controllers: [WhatsAppController],
    providers: [WhatsAppService],
    exports: [WhatsAppService],
})
export class WhatsAppModule { }
