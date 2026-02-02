import { Injectable, UnauthorizedException, ConflictException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto, RegisterDto } from './dto';
import { MailService } from '../mail/mail.service';

@Injectable()
export class AuthService {
  private otpMap = new Map<string, string>();

  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
  ) { }

  async sendEmailOtp(email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    this.otpMap.set(email, otp);

    try {
      await this.mailService.sendOtp(email, otp);
      this.logger.log(`OTP sent to ${email}`);
    } catch (e) {
      this.logger.error(`Mail Error: ${e.message}`);
      throw new BadRequestException(`Failed to send OTP email: ${e.message}`);
    }

    return { success: true, message: 'OTP sent successfully' };
  }

  async verifyEmailOtp(email: string, otp: string) {
    const stored = this.otpMap.get(email);
    if (!stored) throw new BadRequestException('OTP expired or not requested');
    if (stored !== otp) throw new BadRequestException('Invalid OTP');
    this.otpMap.delete(email);
    return { success: true, message: 'Verified' };
  }

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

      profession: registerDto.profession,
      address: registerDto.address,

      registeredArea: registerDto.registeredArea,
      registeredAreaId: registerDto.registeredAreaId,
      identityDocumentUrl: registerDto.identityDocumentUrl,
      identityDocumentType: registerDto.identityDocumentType,

      authorityCode: registerDto.authorityCode,
      department: registerDto.department,
      registrationNumber: registerDto.registrationNumber,
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
        phone: user.phone,
        role: user.role,
        profession: user.profession,
        address: user.address,
        registeredArea: user.registeredArea,
        identityDocumentUrl: user.identityDocumentUrl,
        identityDocumentType: user.identityDocumentType,
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
