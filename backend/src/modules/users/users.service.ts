import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as bcrypt from 'bcrypt';
import { FIREBASE_APP } from '../../firebase';
import { User } from './user.interface';
import { CreateUserDto, UpdateUserDto } from './dto';
import { UserRole } from '../../common/enums';

@Injectable()
export class UsersService {
  private db: admin.firestore.Firestore;
  private usersCollection: admin.firestore.CollectionReference;

  constructor(@Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App) {
    this.db = admin.firestore(this.firebaseApp);
    this.usersCollection = this.db.collection('users');
  }

  async create(createUserDto: CreateUserDto): Promise<User> {
    const passwordHash = await bcrypt.hash(createUserDto.password, 10);

    const userRef = this.usersCollection.doc();
    const now = new Date();

    const user: User = {
      id: userRef.id,
      email: createUserDto.email,
      passwordHash,
      fullName: createUserDto.fullName,
      phone: createUserDto.phone,
      role: createUserDto.role || UserRole.CITIZEN,
      isVerified: false,
      isActive: true,
      verificationCount: 0,
      reputationScore: 0,
      createdAt: now,
      updatedAt: now,
    };

    await userRef.set(user);
    return user;
  }

  async findById(id: string): Promise<User> {
    const doc = await this.usersCollection.doc(id).get();
    if (!doc.exists) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return doc.data() as User;
  }

  async findByEmail(email: string): Promise<User | null> {
    const snapshot = await this.usersCollection.where('email', '==', email).limit(1).get();
    if (snapshot.empty) {
      return null;
    }
    return snapshot.docs[0].data() as User;
  }

  async findByPhone(phone: string): Promise<User | null> {
    const snapshot = await this.usersCollection.where('phone', '==', phone).limit(1).get();
    if (snapshot.empty) {
      return null;
    }
    return snapshot.docs[0].data() as User;
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const userRef = this.usersCollection.doc(id);
    const doc = await userRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const updateData = {
      ...updateUserDto,
      updatedAt: new Date(),
    };

    await userRef.update(updateData);
    return this.findById(id);
  }

  async updateLocation(id: string, latitude: number, longitude: number): Promise<User> {
    const userRef = this.usersCollection.doc(id);
    const doc = await userRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    await userRef.update({
      lastKnownLocation: { latitude, longitude },
      updatedAt: new Date(),
    });

    return this.findById(id);
  }

  async incrementVerificationCount(id: string): Promise<User> {
    const userRef = this.usersCollection.doc(id);
    const doc = await userRef.get();

    if (!doc.exists) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const user = doc.data() as User;

    await userRef.update({
      verificationCount: user.verificationCount + 1,
      reputationScore: user.reputationScore + 10,
      updatedAt: new Date(),
    });

    return this.findById(id);
  }

  async isVolunteer(userId: string): Promise<boolean> {
    const user = await this.findById(userId);
    return (
      user.role === UserRole.VOLUNTEER ||
      user.role === UserRole.AUTHORITY ||
      user.role === UserRole.ADMIN
    );
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.passwordHash);
  }
}
