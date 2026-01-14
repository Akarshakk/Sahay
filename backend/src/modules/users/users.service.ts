import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity';
import { CreateUserDto, UpdateUserDto } from './dto';
import { UserRole } from '../../common/enums';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const passwordHash = await bcrypt.hash(createUserDto.password, 10);

    const user = this.userRepository.create({
      ...createUserDto,
      passwordHash,
    });

    return this.userRepository.save(user);
  }

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { email } });
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findById(id);
    Object.assign(user, updateUserDto);
    return this.userRepository.save(user);
  }

  async updateLocation(
    id: string,
    latitude: number,
    longitude: number,
  ): Promise<User> {
    const user = await this.findById(id);
    // PostGIS Point format
    user.lastKnownLocation = `POINT(${longitude} ${latitude})`;
    return this.userRepository.save(user);
  }

  async incrementVerificationCount(id: string): Promise<User> {
    const user = await this.findById(id);
    user.verificationCount += 1;
    user.reputationScore += 10; // Reward for verifying
    return this.userRepository.save(user);
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
