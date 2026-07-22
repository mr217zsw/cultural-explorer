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

@Controller('health')
class HealthController {
  @Get() health() { return { status: 'ok', service: 'cultural-explorer-api', uptime: process.uptime() }; }
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
  ],
  controllers: [HealthController],
})
export class AppModule {}

