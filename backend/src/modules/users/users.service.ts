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

      // Profile fields
      profession: createUserDto.profession || null,
      address: createUserDto.address || null,

      // Area-based assignment
      registeredArea: createUserDto.registeredArea || null,
      registeredAreaId: createUserDto.registeredAreaId || null,

      // Identity document
      identityDocumentUrl: createUserDto.identityDocumentUrl || null,
      identityDocumentType: (createUserDto.identityDocumentType || null) as User['identityDocumentType'],

      // Authority-specific fields
      authorityCode: createUserDto.authorityCode || null,
      department: createUserDto.department || null,
      registrationNumber: createUserDto.registrationNumber || null,

      // Verification status
      phoneVerified: false,
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

    console.log('DEBUG: Updating user', id, JSON.stringify(updateUserDto, null, 2));

    if (!doc.exists) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    try {
      // Build update object with only provided fields
      const updateData: any = {};
      
      // Only include fields that are defined in the DTO
      if (updateUserDto.fullName !== undefined) updateData.fullName = updateUserDto.fullName;
      if (updateUserDto.phone !== undefined) updateData.phone = updateUserDto.phone;
      if (updateUserDto.avatarUrl !== undefined) updateData.avatarUrl = updateUserDto.avatarUrl;
      if (updateUserDto.profession !== undefined) updateData.profession = updateUserDto.profession;
      if (updateUserDto.address !== undefined) updateData.address = updateUserDto.address;
      if (updateUserDto.registeredArea !== undefined) updateData.registeredArea = updateUserDto.registeredArea;
      if (updateUserDto.registeredAreaId !== undefined) updateData.registeredAreaId = updateUserDto.registeredAreaId;
      if (updateUserDto.identityDocumentUrl !== undefined) updateData.identityDocumentUrl = updateUserDto.identityDocumentUrl;
      if (updateUserDto.identityDocumentType !== undefined) updateData.identityDocumentType = updateUserDto.identityDocumentType;
      
      // Handle emergency contacts - convert to plain objects
      if (updateUserDto.emergencyContacts !== undefined) {
        updateData.emergencyContacts = updateUserDto.emergencyContacts.map(contact => ({
          name: contact.name,
          phone: contact.phone,
          relation: contact.relation,
        }));
        console.log('DEBUG: Saving emergency contacts:', JSON.stringify(updateData.emergencyContacts, null, 2));
      }
      
      updateData.updatedAt = new Date();

      console.log('DEBUG: Final update data:', JSON.stringify(updateData, null, 2));
      await userRef.update(updateData);
      console.log('DEBUG: User updated successfully');
      
      const updatedUser = await this.findById(id);
      console.log('DEBUG: Retrieved updated user with emergencyContacts:', JSON.stringify(updatedUser.emergencyContacts, null, 2));
      console.log('DEBUG: Full updated user being returned:', JSON.stringify(updatedUser, null, 2));
      return updatedUser;
    } catch (error) {
      console.error('Error updating user:', error);
      throw error;
    }
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
