/**
 * WhatsApp Chatbot Controller
 * Webhook endpoint for Twilio WhatsApp messages
 * 
 * This controller is completely isolated and uses its own route prefix
 */

import { Controller, Post, Get, Body, Res, Logger, HttpCode, Req } from '@nestjs/common';
import { Response, Request } from 'express';
import { WhatsAppService } from './whatsapp.service';

@Controller('webhook/whatsapp')
export class WhatsAppController {
    private readonly logger = new Logger(WhatsAppController.name);

    constructor(private readonly whatsAppService: WhatsAppService) { }

    /**
     * Health check endpoint (for testing)
     */
    @Get()
    healthCheck(): string {
        return 'WhatsApp webhook is active!';
    }

    /**
     * Twilio Webhook Endpoint
     * Receives incoming WhatsApp messages and returns TwiML response
     * 
     * Route: POST /api/v1/webhook/whatsapp
     * 
     * NOTE: We use @Body() without a DTO type to bypass NestJS validation
     * because Twilio sends many fields that we don't need to validate
     */
    @Post()
    @HttpCode(200)
    async handleWebhook(
        @Body() body: Record<string, any>,
        @Res() res: Response,
    ): Promise<void> {
        try {
            this.logger.log(`📥 Incoming WhatsApp webhook: ${JSON.stringify(body)}`);

            // Extract the fields we need from Twilio's payload
            const dto = {
                From: body.From || body.from || '',
                Body: body.Body || body.body || '',
                ProfileName: body.ProfileName || body.profileName,
                Latitude: body.Latitude || body.latitude,
                Longitude: body.Longitude || body.longitude,
                MessageSid: body.MessageSid || body.messageSid,
                AccountSid: body.AccountSid || body.accountSid,
            };

            this.logger.log(`📱 Message from ${dto.From}: "${dto.Body}"`);

            // Process message and get response
            const replyMessage = await this.whatsAppService.handleMessage(dto);

            // Return TwiML response (Twilio's XML format)
            const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Message>${this.escapeXml(replyMessage)}</Message>
</Response>`;

            res.set('Content-Type', 'text/xml');
            res.send(twiml);

        } catch (error) {
            this.logger.error(`❌ WhatsApp webhook error: ${error.message}`, error.stack);

            // Return error message via TwiML
            const errorTwiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Message>❌ Sorry, something went wrong. Please try again or call 112 for emergencies.</Message>
</Response>`;

            res.set('Content-Type', 'text/xml');
            res.status(200).send(errorTwiml); // Always 200 to prevent Twilio retries
        }
    }

    /**
     * Escape special XML characters
     */
    private escapeXml(text: string): string {
        return text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }
}
