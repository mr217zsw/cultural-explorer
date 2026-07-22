import { Controller, Get, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { resolve } from 'path';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { RegionsModule } from './regions/regions.module';
import { QuizModule } from './quiz/quiz.module';
import { MnemonicModule } from './mnemonic/mnemonic.module';
import { UsersModule } from './users/users.module';
import { UploadModule } from './upload/upload.module';
import { TTSModule } from './tts/tts.module';
import { ImageGenModule } from './image-gen/image-gen.module';
import { ContentModule } from './content/content.module';
import { ChapterModule } from './chapter/chapter.module';
import { TimelineEventModule } from './timeline-event/timeline-event.module';
import { CuisineModule } from './cuisine/cuisine.module';
import { HeritageModule } from './heritage/heritage.module';
import { CheckinModule } from './checkin/checkin.module';
import { BadgeModule } from './badge/badge.module';

@Controller('health')
class HealthController {
  @Get() health() { return { status: 'ok', service: 'cultural-explorer-api', version: '4.0', uptime: process.uptime() }; }
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot({
      rootPath: resolve(process.cwd(), '..', 'miniapp', 'static'),
      serveRoot: '/static',
    }),
    PrismaModule,
    CommonModule,
    AuthModule,
    RegionsModule,
    QuizModule,
    MnemonicModule,
    UsersModule,
    UploadModule,
    // v4.0 新增模块
    TTSModule,
    ImageGenModule,
    ContentModule,
    ChapterModule,
    TimelineEventModule,
    CuisineModule,
    HeritageModule,
    CheckinModule,
    BadgeModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
