import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { Model } from 'mongoose';

@Injectable()
export class AuthService {
  constructor(@InjectModel('User') private readonly userModel: Model<any>) {}

  async login(
    username: string,
    password: string,
  ): Promise<{ accessToken: string }> {
    const { jwtSecret } = this.getConfiguration();
    const user = await this.userModel.findOne({ username }).exec();

    if (!user || !(await bcrypt.compare(password, user.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return {
      accessToken: this.createAccessToken(user.username, jwtSecret),
    };
  }

  async register(
    username: string,
    password: string,
  ): Promise<{ accessToken: string }> {
    const { jwtSecret } = this.getConfiguration();
    const existingUser = await this.userModel.findOne({ username }).exec();

    if (existingUser) {
      throw new ConflictException('Username already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new this.userModel({
      username,
      password: hashedPassword,
    });

    await user.save();

    return {
      accessToken: this.createAccessToken(user.username, jwtSecret),
    };
  }

  private createAccessToken(username: string, jwtSecret: string): string {
    return jwt.sign({ uid: username }, jwtSecret, {
      algorithm: 'HS256',
      expiresIn: '1h',
      header: { typ: 'JWT', alg: 'HS256' },
    });
  }

  private getConfiguration(): {
    jwtSecret: string;
  } {
    const jwtSecret = process.env.JWT_SECRET;

    if (!jwtSecret || jwtSecret.length < 32) {
      throw new Error('JWT_SECRET is not configured securely');
    }

    return { jwtSecret };
  }
}
