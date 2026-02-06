import { Injectable, Logger, Inject } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { UseFilters } from '@nestjs/common';
import { CreateBroadcastDto } from './dto/create-broadcast.dto';
import { EventsGateway } from '../websocket/events.gateway';

@Injectable()
export class BroadcastsService {
    private readonly logger = new Logger(BroadcastsService.name);
    private db: admin.firestore.Firestore;
    private broadcastsCollection: admin.firestore.CollectionReference;

    constructor(
        @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
        private readonly eventsGateway: EventsGateway,
    ) {
        this.db = admin.firestore(this.firebaseApp);
        this.broadcastsCollection = this.db.collection('broadcasts');
    }

    async create(createBroadcastDto: CreateBroadcastDto) {
        const { region, ...data } = createBroadcastDto;

        // 1. Save to Firestore
        const broadcastRef = this.broadcastsCollection.doc();
        const broadcast = {
            id: broadcastRef.id,
            ...data,
            region,
            createdAt: new Date(),
        };

        await broadcastRef.set(broadcast);
        this.logger.log(`Broadcast created: ${broadcast.id} for region: ${region}`);

        // 2. Send Real-time Notification via WebSocket
        this.eventsGateway.broadcastToRegion(region, broadcast);

        return broadcast;
    }

    async findAll(region: string) {
        // Only return broadcasts from the last 12 hours
        const twelveHoursAgo = new Date(Date.now() - 12 * 60 * 60 * 1000);

        const snapshot = await this.broadcastsCollection
            .where('region', '==', region)
            .where('createdAt', '>=', twelveHoursAgo)
            .orderBy('createdAt', 'desc')
            .limit(20)
            .get();

        return snapshot.docs.map(doc => doc.data());
    }
}
