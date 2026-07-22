import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TimelineEventService {
  constructor(private prisma: PrismaService) {}

  findByRegion(regionId: string) {
    return this.prisma.timelineEvent.findMany({
      where: { regionId },
      orderBy: [{ yearNum: 'asc' }, { sortOrder: 'asc' }],
    });
  }
}
