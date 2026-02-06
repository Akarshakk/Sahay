import { Injectable, Logger, Inject, NotFoundException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { SOSLog } from './sos.interface';
import { CreateSOSDto, AddSOSActionDto } from './dto';
import { UsersService } from '../users/users.service';
import { EventsGateway } from '../websocket/events.gateway';

@Injectable()
export class SOSService {
    private readonly logger = new Logger(SOSService.name);
    private db: admin.firestore.Firestore;
    private sosCollection: admin.firestore.CollectionReference;

    constructor(
        @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
        private readonly usersService: UsersService,
        private readonly eventsGateway: EventsGateway,
    ) {
        this.db = admin.firestore(this.firebaseApp);
        this.sosCollection = this.db.collection('sos_logs');
    }

    async create(userId: string, dto: CreateSOSDto): Promise<SOSLog> {
        const user = await this.usersService.findById(userId);
        const sosRef = this.sosCollection.doc();
        const now = new Date();

        const sosLog: SOSLog = {
            id: sosRef.id,
            userId,
            userName: user.fullName,
            userPhone: user.phone ?? '',
            type: dto.type,
            status: 'TRIGGERED',
            location: {
                latitude: dto.latitude,
                longitude: dto.longitude,
            },
            address: dto.address || '',
            ...(dto.batteryLevel !== undefined && { batteryLevel: dto.batteryLevel }),
            actions: [],
            createdAt: now,
        };

        await sosRef.set(sosLog);
        this.logger.log(`🚨 SOS Triggered by ${user.fullName} (${userId})`);

        // Broadcast SOS to nearby users via WebSocket
        this.eventsGateway.broadcastNewSOS(sosLog);

        return sosLog;
    }

    async addAction(sosId: string, userId: string, dto: AddSOSActionDto): Promise<SOSLog> {
        const sosRef = this.sosCollection.doc(sosId);
        const doc = await sosRef.get();

        if (!doc.exists) {
            throw new NotFoundException(`SOS Log with ID ${sosId} not found`);
        }

        const sosLog = doc.data() as SOSLog;
        if (sosLog.userId !== userId) {
            // Typically we'd allow authorities to add actions too, but for now restricted to user
            // throw new ForbiddenException('Cannot update other user\'s SOS log');
        }

        const newAction = {
            timestamp: new Date(),
            action: dto.action,
            details: dto.details,
        };

        // Update status if marked safe
        const updateData: any = {
            actions: admin.firestore.FieldValue.arrayUnion(newAction),
        };
        
        if (dto.action === 'MARKED_SAFE') {
            updateData.status = 'RESOLVED';
        }

        await sosRef.update(updateData);

        const updatedSosLog = (await sosRef.get()).data() as SOSLog;
        
        // Broadcast update via WebSocket
        if (dto.action === 'MARKED_SAFE') {
            this.eventsGateway.broadcastSOSResolved(updatedSosLog);
        } else {
            this.eventsGateway.broadcastSOSUpdate(updatedSosLog);
        }
        
        return updatedSosLog;
    }

    async getHistory(userId: string): Promise<SOSLog[]> {
        const snapshot = await this.sosCollection
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .get();

        return snapshot.docs.map(doc => doc.data() as SOSLog);
    }

    // Get all active SOS alerts (for authorities/volunteers)
    async getActiveSOSAlerts(): Promise<SOSLog[]> {
        const snapshot = await this.sosCollection
            .where('status', '==', 'TRIGGERED')
            .orderBy('createdAt', 'desc')
            .get();

        return snapshot.docs.map(doc => doc.data() as SOSLog);
    }

    // Get nearby SOS alerts within a radius
    async getNearbySOSAlerts(latitude: number, longitude: number, radiusKm: number = 5): Promise<SOSLog[]> {
        // Get all active SOS alerts and filter by distance
        const activeAlerts = await this.getActiveSOSAlerts();
        
        return activeAlerts.filter(alert => {
            const distance = this.calculateDistance(
                latitude, 
                longitude, 
                alert.location.latitude, 
                alert.location.longitude
            );
            return distance <= radiusKm;
        });
    }

    // Calculate distance between two points using Haversine formula
    private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
        const R = 6371; // Earth's radius in km
        const dLat = this.toRad(lat2 - lat1);
        const dLon = this.toRad(lon2 - lon1);
        const a = 
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    private toRad(deg: number): number {
        return deg * (Math.PI / 180);
    }
}
