import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../common/current-user.decorator';
import { BadgeService } from './badge.service';

@Controller('badges')
@UseGuards(AuthGuard('jwt'))
export class BadgeController {
  constructor(private readonly badgeService: BadgeService) {}

  @Get()
  getUserBadges(@CurrentUser() user: { sub: string }) {
    return this.badgeService.getUserBadges(user.sub);
  }

  @Get('all')
  getAllBadges(@CurrentUser() user: { sub: string }) {
    return this.badgeService.getAllBadges(user.sub);
  }
}
