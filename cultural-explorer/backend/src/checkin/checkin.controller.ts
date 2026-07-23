import { Controller, Post, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { CheckinService } from './checkin.service';

@Controller('checkin')
@UseGuards(JwtAuthGuard)
export class CheckinController {
  constructor(private readonly checkinService: CheckinService) {}

  @Post('daily')
  daily(@CurrentUser() user: { sub: string }) {
    return this.checkinService.checkin(user.sub);
  }

  @Get('stats')
  stats(@CurrentUser() user: { sub: string }) {
    return this.checkinService.stats(user.sub);
  }
}
