import { Module } from '@nestjs/common';
import { TTSService } from './tts.service';
import { TTSController } from './tts.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TTSController],
  providers: [TTSService],
  exports: [TTSService],
})
export class TTSModule {}
