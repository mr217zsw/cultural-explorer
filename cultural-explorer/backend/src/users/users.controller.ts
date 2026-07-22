import { Body, Controller, Get, Put, Query, UseGuards } from '@nestjs/common';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { UsersService } from './users.service';

class ProfileDto {
  @IsOptional() @IsString() @MaxLength(30) nickname?: string;
  @IsOptional() @IsString() avatar?: string;
}

@Controller('user')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}
  @Get('profile') profile(@CurrentUser() user: { sub: string }) { return this.users.profile(user.sub); }
  @Put('profile') update(@CurrentUser() user: { sub: string }, @Body() dto: ProfileDto) { return this.users.update(user.sub, dto); }
  @Get('ranking') ranking(@Query('limit') limit?: string) { return this.users.ranking(Number(limit ?? 100)); }
  @Get('stats') stats(@CurrentUser() user: { sub: string }) { return this.users.stats(user.sub); }
}

