import { Module } from '@nestjs/common';
import { JWTGuard } from '../guards/jwt.guard';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService, JWTGuard],
  exports: [JWTGuard],
})
export class AuthModule {}
