import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto, RegisterDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) { }

  async register(registerDto: RegisterDto) {
    // Check if user already exists
    const existingUser = await this.usersService.findByEmail(registerDto.email);
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Create user
    const user = await this.usersService.create({
      email: registerDto.email,
      password: registerDto.password,
      fullName: registerDto.fullName,
      phone: registerDto.phone,
      role: registerDto.role,
    });

    // Generate token
    const token = this.generateToken(user.id, user.email, user.role);

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
      accessToken: token,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByPhone(loginDto.phone);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await this.usersService.validatePassword(
      user,
      loginDto.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const token = this.generateToken(user.id, user.email, user.role);

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
      accessToken: token,
    };
  }

  private generateToken(userId: string, email: string, role: string): string {
    const payload = { sub: userId, email, role };
    return this.jwtService.sign(payload);
  }

  async validateUser(userId: string) {
    return this.usersService.findById(userId);
  }

  async verifyFirebaseToken(idToken: string) {
    try {
      // Import firebase-admin dynamically or inject it if you possess a provider
      // Assuming a clean approach: import * as admin from 'firebase-admin'; 
      // But better to use the specific provider you might have. 
      // Given the file structure showing src/firebase/firebase.provider.ts, let's use that if possible 
      // OR just use the global admin instance since nestjs-firebase usually initializes it globally or use a service.

      // Checking local imports showed 'firebase-admin' in package.json.
      // Let's assume standard admin usage.
      const admin = require('firebase-admin');
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      throw new UnauthorizedException('Invalid Firebase token');
    }
  }
}
