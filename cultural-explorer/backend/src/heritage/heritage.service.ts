import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HeritageService {
  constructor(private prisma: PrismaService) {}

  findByRegion(regionId: string) {
    return this.prisma.intangibleHeritage.findMany({
      where: { regionId },
      orderBy: { sortOrder: 'asc' },
    });
  }
}
