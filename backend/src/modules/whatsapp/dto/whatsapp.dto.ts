/**
 * WhatsApp Chatbot Module - DTOs
 * Isolated module for handling WhatsApp webhook requests from Twilio
 */

import { IsString, IsOptional } from 'class-validator';

/**
 * Twilio sends webhook data in URL-encoded format
 * Making all fields optional to prevent validation errors - we'll handle missing data in service
 */
export class TwilioWebhookDto {
    @IsOptional()
    @IsString()
    From?: string;  // WhatsApp phone number (e.g., "whatsapp:+919876543210")

    @IsOptional()
    @IsString()
    Body?: string;  // Message text

    @IsOptional()
    @IsString()
    ProfileName?: string;  // User's WhatsApp name

    @IsOptional()
    @IsString()
    Latitude?: string;  // If user shares location

    @IsOptional()
    @IsString()
    Longitude?: string;  // If user shares location

    @IsOptional()
    @IsString()
    MessageSid?: string;  // Twilio message ID

    @IsOptional()
    @IsString()
    AccountSid?: string;  // Twilio account ID

    @IsOptional()
    @IsString()
    To?: string;  // Twilio number

    @IsOptional()
    @IsString()
    SmsMessageSid?: string;

    @IsOptional()
    @IsString()
    NumMedia?: string;

    @IsOptional()
    @IsString()
    SmsSid?: string;

    @IsOptional()
    @IsString()
    WaId?: string;  // WhatsApp ID

    @IsOptional()
    @IsString()
    SmsStatus?: string;

    @IsOptional()
    @IsString()
    NumSegments?: string;

    @IsOptional()
    @IsString()
    ReferralNumMedia?: string;

    @IsOptional()
    @IsString()
    ApiVersion?: string;
}

/**
 * User session stored in memory/cache for conversation state
 */
export interface WhatsAppSession {
    phone: string;
    state: 'MENU' | 'AWAITING_INCIDENT_TYPE' | 'AWAITING_DESCRIPTION' | 'AWAITING_LOCATION' | 'AWAITING_SOS_CONFIRM';
    incidentType?: string;
    description?: string;
    latitude?: number;
    longitude?: number;
    lastActivity: Date;
}
