import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const BADGES = [
  { id: 'first_pass',    name: '初出茅庐', icon: '🌱', condition: '通关1个地区', threshold: 1 },
  { id: 'explorer_5',   name: '文化行者', icon: '🚶', condition: '通关5个地区', threshold: 5 },
  { id: 'explorer_10',  name: '文化达人', icon: '🎯', condition: '通关10个地区', threshold: 10 },
  { id: 'explorer_20',  name: '文化大师', icon: '🏆', condition: '通关20个地区', threshold: 20 },
  { id: 'explorer_34',  name: '华夏通',   icon: '👑', condition: '通关全部34个地区', threshold: 34 },
  { id: 'perfect_score', name: '完美答卷', icon: '💯', condition: '满分通关', threshold: 1 },
  { id: 'streak_7',     name: '坚持不懈', icon: '🔥', condition: '连续7天签到', threshold: 7 },
  { id: 'streak_30',    name: '月度之星', icon: '⭐', condition: '连续30天签到', threshold: 30 },
  { id: 'score_1000',   name: '千分达人', icon: '💰', condition: '积分达到1000', threshold: 1000 },
  { id: 'score_5000',   name: '积分富翁', icon: '💎', condition: '积分达到5000', threshold: 5000 },
];

@Injectable()
export class BadgeService {
  constructor(private prisma: PrismaService) {}

  static ALL_BADGES = BADGES;

  /** 检查并发放用户勋章 */
  async checkAndAward(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) return [];

    const existingBadges = await this.prisma.userBadge.findMany({ where: { userId } });
    const existingIds = new Set(existingBadges.map((b: { badgeId: string }) => b.badgeId));
    const newBadges: typeof BADGES = [];

    for (const badge of BADGES) {
      if (existingIds.has(badge.id)) continue;
      let earned = false;

      switch (badge.id) {
        case 'first_pass':
        case 'explorer_5':
        case 'explorer_10':
        case 'explorer_20':
        case 'explorer_34':
          earned = user.completedCount >= badge.threshold;
          break;
        case 'perfect_score':
          earned = user.perfectCount >= badge.threshold;
          break;
        case 'streak_7':
        case 'streak_30':
          earned = user.streakDays >= badge.threshold;
          break;
        case 'score_1000':
        case 'score_5000':
          earned = user.totalScore >= badge.threshold;
          break;
      }

      if (earned) newBadges.push(badge);
    }

    const created = await Promise.all(
      newBadges.map(b => this.prisma.userBadge.create({
        data: { userId, badgeId: b.id, badgeName: b.name, badgeIcon: b.icon },
      })),
    );

    return created;
  }

  /** 获取用户勋章 */
  async getUserBadges(userId: string) {
    return this.prisma.userBadge.findMany({
      where: { userId, isDisplayed: true },
      orderBy: { earnedAt: 'desc' },
    });
  }

  /** 获取所有勋章定义及用户获取状态 */
  async getAllBadges(userId: string) {
    const earned = await this.prisma.userBadge.findMany({ where: { userId } });
    const earnedIds = new Set(earned.map((b: { badgeId: string }) => b.badgeId));

    return BADGES.map(b => ({
      ...b,
      earned: earnedIds.has(b.id),
      earnedAt: earned.find((e: { badgeId: string }) => e.badgeId === b.id)?.earnedAt ?? null,
    }));
  }
}
