import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type ListQuery = { page: number; limit: number; keyword?: string; sort?: string };

@Injectable()
export class RegionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: ListQuery, userId?: string) {
    const where: Prisma.RegionWhereInput = {
      isPublished: true,
      ...(query.keyword ? { OR: [
        { name: { contains: query.keyword, mode: 'insensitive' } },
        { nameEn: { contains: query.keyword, mode: 'insensitive' } },
        { description: { contains: query.keyword, mode: 'insensitive' } },
      ] } : {}),
    };
    const orderBy: Prisma.RegionOrderByWithRelationInput = ['viewCount', 'favoriteCount', 'createdAt'].includes(query.sort ?? '')
      ? { [query.sort!]: 'desc' }
      : { sortOrder: 'asc' };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.region.findMany({ where, orderBy, skip: (query.page - 1) * query.limit, take: query.limit, select: { id: true, name: true, nameEn: true, shortName: true, capital: true, description: true, coverImage: true, viewCount: true, favoriteCount: true } }),
      this.prisma.region.count({ where }),
    ]);
    const records = userId ? await this.prisma.userRecord.findMany({ where: { userId, regionId: { in: items.map((item) => item.id) } } }) : [];
    const progress = new Map(records.map((record) => [record.regionId, record]));
    return {
      items: items.map((item) => ({ ...item, userProgress: progress.get(item.id) ?? null })),
      pagination: { page: query.page, limit: query.limit, total, totalPages: Math.ceil(total / query.limit), hasMore: query.page * query.limit < total },
    };
  }

  async random() {
    const count = await this.prisma.region.count({ where: { isPublished: true } });
    if (!count) return [];
    const skip = Math.max(0, Math.floor(Math.random() * count) - 2);
    return this.prisma.region.findMany({ where: { isPublished: true }, skip, take: 3, orderBy: { sortOrder: 'asc' } });
  }

  async detail(idOrName: string, userId?: string) {
    const region = await this.prisma.region.findFirst({
      where: { OR: [{ id: idOrName }, { name: idOrName }], isPublished: true },
      include: { landmarks: { orderBy: { sortOrder: 'asc' } }, mnemonic: true, _count: { select: { questions: true } } },
    });
    if (!region) throw new NotFoundException('地区不存在');
    await this.prisma.region.update({ where: { id: region.id }, data: { viewCount: { increment: 1 } } });
    const [record, favorite] = userId ? await Promise.all([
      this.prisma.userRecord.findUnique({ where: { userId_regionId: { userId, regionId: region.id } } }),
      this.prisma.favorite.findUnique({ where: { userId_regionId: { userId, regionId: region.id } } }),
    ]) : [null, null];
    return { ...region, mnemonic: region.mnemonic?.content ?? null, questionCount: region._count.questions, userProgress: record, isFavorited: Boolean(favorite) };
  }

  async landmarks(regionId: string) { await this.assertRegion(regionId); return this.prisma.landmark.findMany({ where: { regionId }, orderBy: { sortOrder: 'asc' } }); }

  async questions(regionId: string) {
    await this.assertRegion(regionId);
    return this.prisma.question.findMany({ where: { regionId }, orderBy: { sortOrder: 'asc' }, select: { id: true, regionId: true, question: true, options: true, difficulty: true, category: true, sortOrder: true } });
  }

  async toggleFavorite(regionId: string, userId: string) {
    await this.assertRegion(regionId);
    const existing = await this.prisma.favorite.findUnique({ where: { userId_regionId: { userId, regionId } } });
    await this.prisma.$transaction([
      existing ? this.prisma.favorite.delete({ where: { id: existing.id } }) : this.prisma.favorite.create({ data: { userId, regionId } }),
      this.prisma.region.update({ where: { id: regionId }, data: { favoriteCount: existing ? { decrement: 1 } : { increment: 1 } } }),
    ]);
    return { isFavorited: !existing };
  }

  private async assertRegion(id: string) {
    if (!await this.prisma.region.findUnique({ where: { id }, select: { id: true } })) throw new NotFoundException('地区不存在');
  }
}
