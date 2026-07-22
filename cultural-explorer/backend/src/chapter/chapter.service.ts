import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChapterService {
  constructor(private prisma: PrismaService) {}

  findByRegion(regionId: string) {
    return this.prisma.chapter.findMany({
      where: { regionId, isPublished: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  findOne(id: string) {
    return this.prisma.chapter.findUnique({ where: { id } });
  }
}
