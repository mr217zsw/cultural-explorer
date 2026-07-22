import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}
  async profile(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('用户不存在');
    return user;
  }
  update(id: string, data: { nickname?: string; avatar?: string }) { return this.prisma.user.update({ where: { id }, data }); }
  ranking(limit: number) { return this.prisma.user.findMany({ where: { isActive: true }, take: Math.min(Math.max(limit, 1), 100), orderBy: [{ totalScore: 'desc' }, { completedCount: 'desc' }], select: { id: true, nickname: true, avatar: true, totalScore: true, completedCount: true, maxStreak: true } }); }
  async stats(id: string) {
    const user = await this.profile(id);
    const records = await this.prisma.userRecord.aggregate({ where: { userId: id }, _sum: { correctCount: true, totalQuestions: true, timeSpent: true }, _count: true });
    return { totalScore: user.totalScore, completedCount: user.completedCount, maxStreak: user.maxStreak, recordCount: records._count, correctCount: records._sum.correctCount ?? 0, totalQuestions: records._sum.totalQuestions ?? 0, timeSpent: records._sum.timeSpent ?? 0 };
  }
}
