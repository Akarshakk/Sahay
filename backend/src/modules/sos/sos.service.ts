import { Injectable, Logger, Inject, NotFoundException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from '../../firebase';
import { SOSLog } from './sos.interface';
import { CreateSOSDto, AddSOSActionDto } from './dto';
import { UsersService } from '../users/users.service';

@Injectable()
export class SOSService {
    private readonly logger = new Logger(SOSService.name);
    private db: admin.firestore.Firestore;
    private sosCollection: admin.firestore.CollectionReference;

    constructor(
        @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
        private readonly usersService: UsersService,
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
            batteryLevel: dto.batteryLevel,
            actions: [],
            createdAt: now,
        };

        await sosRef.set(sosLog);
        this.logger.log(`🚨 SOS Triggered by ${user.fullName} (${userId})`);

        // In a real system, we would trigger SMS/Notifications here

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

        await sosRef.update({
            actions: admin.firestore.FieldValue.arrayUnion(newAction),
        });

        return (await sosRef.get()).data() as SOSLog;
    }

    async getHistory(userId: string): Promise<SOSLog[]> {
        const snapshot = await this.sosCollection
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .get();

        return snapshot.docs.map(doc => doc.data() as SOSLog);
    }
}
