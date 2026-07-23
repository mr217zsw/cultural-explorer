import { Controller, Get, Post, Body, Param, Query, UseGuards, BadRequestException } from '@nestjs/common';
import { QuizService } from './quiz.service';
import { QuizV2Service } from './quiz-v2.service';
import { BadgeService } from '../badge/badge.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';

@Controller('quiz')
export class QuizController {
  constructor(
    private readonly quiz: QuizService,
    private readonly quizV2: QuizV2Service,
    private readonly badge: BadgeService,
  ) {}

  // ===== 旧版 API（兼容） =====
  @Post('start') @UseGuards(JwtAuthGuard)
  start(@Body() body: { regionId: string }) {
    return this.quiz.start(body.regionId);
  }

  @Post('submit') @UseGuards(JwtAuthGuard)
  submit(@Body() body: { questionId: string; selectedIndex: number }) {
    return this.quiz.submit(body.questionId, body.selectedIndex);
  }

  @Post('complete') @UseGuards(JwtAuthGuard)
  async complete(@Body() body: any, @CurrentUser() user: { sub: string }) {
    const result = await this.quiz.complete(user.sub, body);
    await this.badge.checkAndAward(user.sub);
    return result;
  }

  @Get('records') @UseGuards(JwtAuthGuard)
  records(@CurrentUser() user: { sub: string }, @Query('regionId') regionId?: string) {
    return this.quiz.records(user.sub, regionId);
  }

  @Get('ranking/:regionId')
  ranking(@Param('regionId') regionId: string, @Query('limit') limit?: string) {
    return this.quiz.ranking(regionId, Number(limit ?? 20));
  }

  // ===== V2 API（新版） =====
  @Post('startV2') @UseGuards(JwtAuthGuard)
  startV2(@Body() body: { regionId: string; difficulty?: number }, @CurrentUser() user: { sub: string }) {
    return this.quizV2.start(user.sub, body.regionId, body.difficulty ?? 1);
  }

  @Post('submitV2') @UseGuards(JwtAuthGuard)
  async submitV2(@Body() body: { questionId: string; answer: any }, @CurrentUser() user: { sub: string }) {
    if (!body.questionId) throw new BadRequestException('questionId is required');
    const result = await this.quizV2.submit(user.sub, body.questionId, body.answer);
    if (result.isGameOver) await this.badge.checkAndAward(user.sub);
    return result;
  }

  @Post('hint') @UseGuards(JwtAuthGuard)
  hint(@Body() body: { questionId: string }, @CurrentUser() user: { sub: string }) {
    return this.quizV2.getHint(user.sub, body.questionId);
  }
}
