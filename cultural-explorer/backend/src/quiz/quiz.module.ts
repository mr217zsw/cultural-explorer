import { Module } from '@nestjs/common';
import { QuizController } from './quiz.controller';
import { QuizService } from './quiz.service';
import { QuizV2Service } from './quiz-v2.service';
import { PrismaModule } from '../prisma/prisma.module';
import { CommonModule } from '../common/common.module';
import { BadgeModule } from '../badge/badge.module';

@Module({
  imports: [PrismaModule, CommonModule, BadgeModule],
  controllers: [QuizController],
  providers: [QuizService, QuizV2Service],
  exports: [QuizV2Service],
})
export class QuizModule {}
