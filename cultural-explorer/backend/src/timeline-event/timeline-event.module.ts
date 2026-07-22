import { Module } from '@nestjs/common';
import { TimelineEventService } from './timeline-event.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [TimelineEventService],
  exports: [TimelineEventService],
})
export class TimelineEventModule {}
