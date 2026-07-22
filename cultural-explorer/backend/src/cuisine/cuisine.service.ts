import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CuisineService {
  constructor(private prisma: PrismaService) {}

  findByRegion(regionId: string) {
    return this.prisma.cuisine.findMany({
      where: { regionId },
      orderBy: { sortOrder: 'asc' },
    });
  }
}
