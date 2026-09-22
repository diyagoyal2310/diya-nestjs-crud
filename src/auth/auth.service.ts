import { Injectable, UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class AuthService {
  constructor() {
    this.getConfiguration();
  }

  login(username: string, password: string): { accessToken: string } {
    const { expectedUsername, expectedPassword, jwtSecret } = this.getConfiguration();

    if (!this.credentialsMatch(username, expectedUsername) || !this.credentialsMatch(password, expectedPassword)) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return {
      accessToken: jwt.sign(
        { uid: expectedUsername },
        jwtSecret,
        { algorithm: 'HS256', expiresIn: '1h', header: { typ: 'JWT', alg: 'HS256' } },
      ),
    };
  }

  private credentialsMatch(provided: string, expected: string): boolean {
    const providedBuffer = Buffer.from(provided || '');
    const expectedBuffer = Buffer.from(expected);

    return providedBuffer.length === expectedBuffer.length
      && crypto.timingSafeEqual(providedBuffer, expectedBuffer);
  }

  private getConfiguration(): { expectedUsername: string; expectedPassword: string; jwtSecret: string } {
    const expectedUsername = process.env.DEV_AUTH_USERNAME;
    const expectedPassword = process.env.DEV_AUTH_PASSWORD;
    const jwtSecret = process.env.JWT_SECRET;

    if (!expectedUsername || !expectedPassword || !jwtSecret || jwtSecret.length < 32) {
      throw new Error('Development authentication environment variables are not configured securely');
    }

    return { expectedUsername, expectedPassword, jwtSecret };
  }
}
