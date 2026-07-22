import { Controller, Post, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../common/current-user.decorator';
import { CheckinService } from './checkin.service';

@Controller('checkin')
@UseGuards(AuthGuard('jwt'))
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
