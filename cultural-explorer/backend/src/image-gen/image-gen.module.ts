import { Module } from '@nestjs/common';
import { ImageGenService } from './image-gen.service';
import { ImageGenController } from './image-gen.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ImageGenController],
  providers: [ImageGenService],
  exports: [ImageGenService],
})
export class ImageGenModule {}
