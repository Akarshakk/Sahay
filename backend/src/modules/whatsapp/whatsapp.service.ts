/**
 * WhatsApp Chatbot Service
 * Handles message processing and integrates with existing Sahay APIs
 * 
 * This is an ISOLATED module - it uses existing services via dependency injection
 * and does not modify any existing code.
 */

import { Injectable, Logger, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { IncidentsService } from '../incidents/incidents.service';
import { SOSService } from '../sos/sos.service';
import { UsersService } from '../users/users.service';
import { EventsGateway } from '../websocket/events.gateway';
import { WhatsAppSession, TwilioWebhookDto } from './dto';
import { IncidentPriority } from '../../common/enums';

@Injectable()
export class WhatsAppService {
    private readonly logger = new Logger(WhatsAppService.name);
    private db: admin.firestore.Firestore;

    // In-memory session store (use Redis in production)
    private sessions: Map<string, WhatsAppSession> = new Map();

    // Session timeout in minutes
    private readonly SESSION_TIMEOUT = 30;

    constructor(
        @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
        private readonly configService: ConfigService,
        private readonly incidentsService: IncidentsService,
        private readonly sosService: SOSService,
        private readonly usersService: UsersService,
        private readonly eventsGateway: EventsGateway,
    ) {
        this.db = admin.firestore(this.firebaseApp);
        this.logger.log('🤖 WhatsApp Chatbot Service initialized');
    }

    /**
     * Main message handler - processes incoming WhatsApp messages
     */
    async handleMessage(dto: TwilioWebhookDto): Promise<string> {
        // Must have From field at minimum
        if (!dto.From) {
            this.logger.warn('Received webhook without From field');
            return 'Welcome to Sahay! Type "hi" to start.';
        }

        const phone = this.normalizePhone(dto.From);

        // Check for location data FIRST (location messages have empty Body)
        if (dto.Latitude && dto.Longitude) {
            this.logger.log(`� Location received from ${phone}: ${dto.Latitude}, ${dto.Longitude}`);
            return await this.handleLocationShared(phone, parseFloat(dto.Latitude), parseFloat(dto.Longitude));
        }

        // For non-location messages, Body is required
        if (!dto.Body) {
            this.logger.warn('Received webhook without Body (and no location)');
            return 'Welcome to Sahay! Type "hi" to start.';
        }

        const message = dto.Body.trim().toLowerCase();

        this.logger.log(`📱 WhatsApp message from ${phone}: "${dto.Body}"`);

        // Get or create session
        let session = this.getSession(phone);

        // Check for menu commands (restart at any point)
        if (message === 'hi' || message === 'hello' || message === 'menu' || message === 'start') {
            return this.showMainMenu(phone);
        }

        // Handle based on current state
        switch (session.state) {
            case 'MENU':
                return await this.handleMenuChoice(phone, message);
            case 'AWAITING_INCIDENT_TYPE':
                return this.handleIncidentType(phone, message);
            case 'AWAITING_DESCRIPTION':
                return await this.handleDescription(phone, message, dto);
            case 'AWAITING_LOCATION':
                return await this.handleLocationInput(phone, message);
            case 'AWAITING_SOS_CONFIRM':
                return await this.handleSOSConfirm(phone, message, dto);
            default:
                return this.showMainMenu(phone);
        }
    }

    /**
     * Show main menu
     */
    private showMainMenu(phone: string): string {
        this.updateSession(phone, { state: 'MENU' });

        return `🆘 *SAHAY Emergency Services*

Welcome! How can we help you today?

*Reply with a number:*
1️⃣ Report an Incident
2️⃣ SOS Emergency
3️⃣ Check Incident Status
4️⃣ Safety Tips
0️⃣ Talk to Operator

_Type 'menu' anytime to see this again._`;
    }

    /**
     * Handle menu choice
     */
    private async handleMenuChoice(phone: string, message: string): Promise<string> {
        switch (message) {
            case '1':
            case 'incident':
            case 'report':
                this.updateSession(phone, { state: 'AWAITING_INCIDENT_TYPE' });
                return `📋 *Report an Incident*

What type of incident do you want to report?

*Reply with a number:*
1️⃣ Fire 🔥
2️⃣ Accident 🚗
3️⃣ Medical Emergency 🏥
4️⃣ Crime/Theft 🚔
5️⃣ Natural Disaster 🌊
6️⃣ Other

_Type 'menu' to go back._`;

            case '2':
            case 'sos':
            case 'emergency':
                this.updateSession(phone, { state: 'AWAITING_SOS_CONFIRM' });
                return `🚨 *SOS EMERGENCY*

⚠️ This will alert emergency services and nearby volunteers with your location.

*Are you sure?*
Reply *YES* to confirm or *NO* to cancel.

📍 Please share your location for faster response.`;

            case '3':
            case 'status':
                return await this.getIncidentStatus(phone);

            case '4':
            case 'tips':
            case 'safety':
                return `🛡️ *Safety Tips*

🔥 *Fire Safety*
• Stay low, smoke rises
• Feel doors before opening
• Use stairs, not elevators

🌊 *Flood Safety*
• Move to higher ground
• Avoid walking in floodwater
• Don't drive through floods

🚗 *Road Safety*
• Always wear seatbelt
• Don't use phone while driving
• Follow speed limits

_Type 'menu' for main options._`;

            case '0':
            case 'operator':
            case 'help':
                return `📞 *Contact Emergency Services*

🚔 Police: 100
🚑 Ambulance: 102
🔥 Fire: 101
☎️ Emergency: 112

Or visit our app for faster assistance.

_Type 'menu' for main options._`;

            default:
                return `❌ Sorry, I didn't understand that.

Please reply with a number (1-4 or 0) or type 'menu' to see options.`;
        }
    }

    /**
     * Handle incident type selection
     */
    private handleIncidentType(phone: string, message: string): string {
        const typeMap: Record<string, string> = {
            '1': 'FIRE',
            '2': 'ACCIDENT',
            '3': 'MEDICAL',
            '4': 'CRIME',
            '5': 'NATURAL_DISASTER',
            '6': 'OTHER',
            'fire': 'FIRE',
            'accident': 'ACCIDENT',
            'medical': 'MEDICAL',
            'crime': 'CRIME',
            'disaster': 'NATURAL_DISASTER',
            'other': 'OTHER',
        };

        const incidentType = typeMap[message];

        if (!incidentType) {
            return `❌ Please select a valid option (1-6).

_Type 'menu' to go back._`;
        }

        this.updateSession(phone, {
            state: 'AWAITING_DESCRIPTION',
            incidentType
        });

        return `📝 *Describe the Incident*

Please provide details about the ${incidentType.replace('_', ' ')} incident:
• What happened?
• How many people involved?
• Any injuries?

_Type your description below:_`;
    }

    /**
     * Handle incident description
     */
    private async handleDescription(phone: string, message: string, dto: TwilioWebhookDto): Promise<string> {
        if (message.length < 10) {
            return `❌ Please provide more details (at least 10 characters).

_Describe what happened:_`;
        }

        const session = this.getSession(phone);

        // Check if we already have location from shared location
        if (session.latitude && session.longitude) {
            // We have location, create incident immediately
            return await this.createIncidentFromSession(phone, message);
        }

        this.updateSession(phone, {
            state: 'AWAITING_LOCATION',
            description: dto.Body  // Keep original case
        });

        return `📍 *Share Your Location*

Please share your current location by:

1️⃣ Tap the 📎 (attachment) icon
2️⃣ Select "Location"
3️⃣ Choose "Send your current location"

Or type your address manually.`;
    }

    /**
     * Handle when user shares WhatsApp location
     */
    private async handleLocationShared(phone: string, latitude: number, longitude: number): Promise<string> {
        const session = this.getSession(phone);

        this.updateSession(phone, { latitude, longitude });

        if (session.state === 'AWAITING_SOS_CONFIRM') {
            // Trigger SOS with location
            return await this.triggerSOS(phone);
        }

        if (session.state === 'AWAITING_LOCATION' && session.description) {
            // Create incident with location
            return await this.createIncidentFromSession(phone, session.description);
        }

        // Store location for future use
        return `📍 Location received: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}

Your location has been saved. What would you like to do?

_Type 'menu' to see options._`;
    }

    /**
     * Handle manual location/address input
     */
    private async handleLocationInput(phone: string, message: string): Promise<string> {
        // For now, we'll use a default location (Mumbai) since we can't geocode text
        // In production, use Google Geocoding API
        const session = this.getSession(phone);

        this.updateSession(phone, {
            latitude: 19.0760,  // Mumbai default
            longitude: 72.8777,
        });

        return await this.createIncidentFromSession(phone, session.description || message);
    }

    /**
     * Create incident from session data
     */
    private async createIncidentFromSession(phone: string, description: string): Promise<string> {
        const session = this.getSession(phone);

        try {
            // Find or create user by phone
            let userId = 'whatsapp_' + phone.replace(/\D/g, '');

            // Map incident type to category (string values used by the system)
            const categoryMap: Record<string, string> = {
                'FIRE': 'safety',
                'ACCIDENT': 'traffic',
                'MEDICAL': 'safety',
                'CRIME': 'safety',
                'NATURAL_DISASTER': 'environment',
                'OTHER': 'other',
            };

            // Ensure title and description meet minimum length requirements
            const incidentTitle = `[WhatsApp] ${session.incidentType || 'Emergency'} incident reported by user`;
            const incidentDescription = description.length >= 20
                ? description
                : `${description} - Reported via WhatsApp chatbot by ${phone}`;

            const incident = await this.incidentsService.create({
                title: incidentTitle,
                description: incidentDescription,
                category: categoryMap[session.incidentType || 'OTHER'] || 'other',
                priority: IncidentPriority.MEDIUM,
                latitude: session.latitude || 19.0760,
                longitude: session.longitude || 72.8777,
                address: 'Reported via WhatsApp',
                reporterPhone: phone,
            }, userId);

            // Clear session
            this.clearSession(phone);

            // Notify via WebSocket (using existing broadcastIncidentUpdate method)
            this.eventsGateway.broadcastIncidentUpdate(incident);

            return `✅ *Incident Reported Successfully!*

📋 *Report ID:* ${incident.id.slice(0, 8).toUpperCase()}
📍 *Type:* ${session.incidentType || 'General'}
🕐 *Time:* ${new Date().toLocaleString('en-IN')}

Authorities in your area have been notified.

_Save your Report ID for tracking._

Type 'menu' for main options.`;

        } catch (error) {
            this.logger.error(`Failed to create incident: ${error.message}`);
            return `❌ Sorry, we couldn't submit your report. Please try again or call 112.

_Type 'menu' to start over._`;
        }
    }

    /**
     * Handle SOS confirmation
     */
    private async handleSOSConfirm(phone: string, message: string, dto: TwilioWebhookDto): Promise<string> {
        if (message === 'yes' || message === 'y') {
            return await this.triggerSOS(phone);
        }

        if (message === 'no' || message === 'n') {
            this.clearSession(phone);
            return `✅ SOS cancelled.

_Type 'menu' for main options._`;
        }

        return `Please reply *YES* to confirm SOS or *NO* to cancel.`;
    }

    /**
     * Trigger SOS alert - Uses SOSService for proper broadcast to volunteers
     */
    private async triggerSOS(phone: string): Promise<string> {
        const session = this.getSession(phone);

        try {
            // Try to find existing user by phone number
            let userId = 'whatsapp_' + phone.replace(/\D/g, '');
            let userName = 'WhatsApp User';
            let emergencyContacts: { name: string; phone: string; relation: string }[] = [];

            try {
                // Look up user by phone in Firestore
                const usersSnapshot = await this.db.collection('users')
                    .where('phone', '==', phone)
                    .limit(1)
                    .get();

                if (!usersSnapshot.empty) {
                    const userData = usersSnapshot.docs[0].data();
                    userId = usersSnapshot.docs[0].id;
                    userName = userData.fullName || 'WhatsApp User';
                    emergencyContacts = userData.emergencyContacts || [];
                    this.logger.log(`📱 Found existing user: ${userName} (${userId})`);
                }
            } catch (lookupError) {
                this.logger.warn(`Could not lookup user by phone: ${lookupError.message}`);
            }

            // Create SOS using SOSService for proper WebSocket broadcast to volunteers
            const sosLog = await this.sosService.create(userId, {
                latitude: session.latitude || 19.0760,
                longitude: session.longitude || 72.8777,
                address: 'Triggered via WhatsApp',
                type: 'POLICE',
            });

            this.clearSession(phone);

            // Build response with emergency contact info
            let contactsAlertMsg = '';
            if (emergencyContacts.length > 0) {
                contactsAlertMsg = `\n✅ ${emergencyContacts.length} emergency contact(s) will be notified`;
            }

            return `🚨 *SOS ALERT SENT!*

📋 *SOS ID:* ${sosLog.id.slice(0, 8).toUpperCase()}
📍 *Location:* ${session.latitude?.toFixed(4) || 'Default'}, ${session.longitude?.toFixed(4) || 'Default'}
🕐 *Time:* ${new Date().toLocaleString('en-IN')}

✅ Emergency services have been notified
✅ Nearby volunteers alerted via app${contactsAlertMsg}

*Stay calm. Help is on the way.*

_Type 'menu' when safe._`;

        } catch (error) {
            this.logger.error(`Failed to trigger SOS: ${error.message}`, error.stack);
            return `❌ SOS failed. Please call 112 immediately!

📞 Emergency: 112
🚔 Police: 100
🚑 Ambulance: 102`;
        }
    }

    /**
     * Get incident status - Queries actual incidents from Firestore
     */
    private async getIncidentStatus(phone: string): Promise<string> {
        try {
            // Query recent incidents reported by this phone number
            const incidentsSnapshot = await this.db.collection('incidents')
                .where('reporterPhone', '==', phone)
                .orderBy('createdAt', 'desc')
                .limit(3)
                .get();

            if (incidentsSnapshot.empty) {
                return `📊 *Incident Status*

No incidents found for your number.

To report an incident, reply *1* from the main menu.

_Type 'menu' for main options._`;
            }

            let statusMsg = `📊 *Your Recent Incidents*\n\n`;

            incidentsSnapshot.docs.forEach((doc, index) => {
                const incident = doc.data();
                const statusEmoji = incident.status === 'RESOLVED' ? '✅' :
                    incident.status === 'IN_PROGRESS' ? '🔄' : '⏳';
                const date = incident.createdAt?.toDate?.() || new Date();

                statusMsg += `${index + 1}. ${statusEmoji} *${incident.title?.slice(0, 30) || 'Incident'}*\n`;
                statusMsg += `   Status: ${incident.status || 'PENDING'}\n`;
                statusMsg += `   Date: ${date.toLocaleDateString('en-IN')}\n\n`;
            });

            statusMsg += `_Type 'menu' for main options._`;
            return statusMsg;

        } catch (error) {
            this.logger.error(`Failed to get incident status: ${error.message}`);
            return `📊 *Incident Status*

Unable to fetch status. Please try again later or check the Sahay app.

_Type 'menu' for main options._`;
        }
    }

    // ============================================
    // Session Management
    // ============================================

    private getSession(phone: string): WhatsAppSession {
        const existing = this.sessions.get(phone);

        if (existing) {
            // Check if session expired
            const minutesSinceActivity = (Date.now() - existing.lastActivity.getTime()) / 60000;
            if (minutesSinceActivity > this.SESSION_TIMEOUT) {
                this.sessions.delete(phone);
            } else {
                return existing;
            }
        }

        // Create new session
        const newSession: WhatsAppSession = {
            phone,
            state: 'MENU',
            lastActivity: new Date(),
        };
        this.sessions.set(phone, newSession);
        return newSession;
    }

    private updateSession(phone: string, updates: Partial<WhatsAppSession>): void {
        const session = this.getSession(phone);
        Object.assign(session, updates, { lastActivity: new Date() });
        this.sessions.set(phone, session);
    }

    private clearSession(phone: string): void {
        this.sessions.delete(phone);
    }

    private normalizePhone(twilioPhone: string): string {
        // Remove "whatsapp:" prefix
        return twilioPhone.replace('whatsapp:', '').replace('+', '');
    }
}
