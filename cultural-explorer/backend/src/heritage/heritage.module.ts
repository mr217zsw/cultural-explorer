import { Module } from '@nestjs/common';
import { HeritageService } from './heritage.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [HeritageService],
  exports: [HeritageService],
})
export class HeritageModule {}
