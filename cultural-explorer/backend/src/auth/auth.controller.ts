import { Body, Controller, Post } from '@nestjs/common';
import { IsNotEmpty, IsString } from 'class-validator';
import { AuthService } from './auth.service';

class AnonymousLoginDto {
  @IsString() @IsNotEmpty() deviceId!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post('anonymous') login(@Body() dto: AnonymousLoginDto) { return this.auth.anonymous(dto.deviceId); }
}

