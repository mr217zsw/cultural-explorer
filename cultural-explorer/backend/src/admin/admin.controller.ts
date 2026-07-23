import { Controller, Get, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard)
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('stats')
  async stats() {
    const [regionCount, userCount, questionCount, totalViews, totalFavorites, totalRecords] = await Promise.all([
      this.prisma.region.count({ where: { isPublished: true } }),
      this.prisma.user.count(),
      this.prisma.question.count(),
      this.prisma.region.aggregate({ _sum: { visitCount: true } }),
      this.prisma.region.aggregate({ _sum: { favoriteCount: true } }),
      this.prisma.userRecord.count({ where: { isCompleted: true } }),
    ]);

    return {
      overview: { regionCount, userCount, questionCount, totalViews: totalViews._sum.visitCount || 0, totalFavorites: totalFavorites._sum.favoriteCount || 0, totalCompletions: totalRecords },
    };
  }

  @Get('regions-top')
  async topRegions() {
    return this.prisma.region.findMany({ orderBy: { visitCount: 'desc' }, take: 10, select: { id: true, name: true, visitCount: true, favoriteCount: true, _count: { select: { questions: true, records: true } } } });
  }

  @Get('questions-stats')
  async questionsStats() {
    const [total, byDifficulty, byType] = await Promise.all([
      this.prisma.question.count(),
      this.prisma.question.groupBy({ by: ['difficulty'], _count: true }),
      this.prisma.question.groupBy({ by: ['type'], _count: true }),
    ]);
    return { total, byDifficulty, byType };
  }

  @Get('daily-activity')
  async dailyActivity() {
    const weekAgo = new Date(Date.now() - 7 * 86400000);
    const [dailyCheckins, dailyRecords] = await Promise.all([
      this.prisma.dailyCheckin.findMany({ where: { checkinDate: { gte: weekAgo } }, orderBy: { checkinDate: 'desc' } }),
      this.prisma.userRecord.findMany({ where: { updatedAt: { gte: weekAgo } }, orderBy: { updatedAt: 'desc' }, select: { userId: true, regionId: true, updatedAt: true } }),
    ]);
    return { dailyCheckinCount: dailyCheckins.length, dailyRecordCount: dailyRecords.length };
  }

  @Get('contents-overview')
  async contentsOverview() {
    const [chapterCount, timelineCount, cuisineCount, heritageCount, badgesCount] = await Promise.all([
      this.prisma.chapter.count(),
      this.prisma.timelineEvent.count(),
      this.prisma.cuisine.count(),
      this.prisma.intangibleHeritage.count(),
      this.prisma.userBadge.count(),
    ]);
    return { chapterCount, timelineCount, cuisineCount, heritageCount, badgesIssued: badgesCount };
  }
}
