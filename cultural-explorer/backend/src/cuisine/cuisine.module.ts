import { Module } from '@nestjs/common';
import { CuisineService } from './cuisine.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [CuisineService],
  exports: [CuisineService],
})
export class CuisineModule {}
