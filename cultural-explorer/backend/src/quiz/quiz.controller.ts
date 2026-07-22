import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsArray, IsInt, IsOptional, IsString, Max, Min, ValidateNested } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { QuizService } from './quiz.service';

class StartDto { @IsString() regionId!: string; }
class SubmitDto { @IsString() questionId!: string; @IsInt() @Min(0) @Max(3) selectedIndex!: number; }
class AnswerDto { @IsString() questionId!: string; @IsInt() @Min(0) @Max(3) selectedIndex!: number; }
class CompleteDto {
  @IsString() regionId!: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => AnswerDto) answers!: AnswerDto[];
  @IsOptional() @IsInt() @Min(0) timeSpent?: number;
}

@Controller('quiz')
@UseGuards(JwtAuthGuard)
export class QuizController {
  constructor(private readonly quiz: QuizService) {}
  @Post('start') start(@Body() dto: StartDto) { return this.quiz.start(dto.regionId); }
  @Post('submit') submit(@Body() dto: SubmitDto) { return this.quiz.submit(dto.questionId, dto.selectedIndex); }
  @Post('complete') complete(@Body() dto: CompleteDto, @CurrentUser() user: { sub: string }) { return this.quiz.complete(user.sub, dto); }
  @Get('records') records(@CurrentUser() user: { sub: string }, @Query('regionId') regionId?: string) { return this.quiz.records(user.sub, regionId); }
  @Get('ranking/:regionId') ranking(@Param('regionId') regionId: string, @Query('limit') limit?: string) { return this.quiz.ranking(regionId, Number(limit ?? 50)); }
}

