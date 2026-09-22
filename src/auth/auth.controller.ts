import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../shared/public.decorator';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login')
  async login(@Body() loginDto: LoginDto): Promise<{ accessToken: string }> {
    return this.authService.login(loginDto.username, loginDto.password);
  }

  @Public()
  @Post('register')
  async register(@Body() loginDto: LoginDto): Promise<{ accessToken: string }> {
    return this.authService.register(loginDto.username, loginDto.password);
  }
}
