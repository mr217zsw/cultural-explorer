import { Controller, Get, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { RegionsModule } from './regions/regions.module';
import { QuizModule } from './quiz/quiz.module';
import { MnemonicModule } from './mnemonic/mnemonic.module';
import { UsersModule } from './users/users.module';

@Controller('health')
class HealthController {
  @Get() health() { return { status: 'ok', service: 'cultural-explorer-api' }; }
}

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), PrismaModule, AuthModule, RegionsModule, QuizModule, MnemonicModule, UsersModule],
  controllers: [HealthController],
})
export class AppModule {}

