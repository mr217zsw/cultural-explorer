import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CheckinService {
  constructor(private prisma: PrismaService) {}

  async checkin(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const lastCheckin = await this.prisma.dailyCheckin.findFirst({
      where: { userId },
      orderBy: { checkinDate: 'desc' },
    });

    if (lastCheckin) {
      const lastDate = new Date(lastCheckin.checkinDate);
      lastDate.setHours(0, 0, 0, 0);
      if (lastDate.getTime() === today.getTime()) {
        throw new BadRequestException('今日已签到');
      }

      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const isConsecutive = lastDate.getTime() === yesterday.getTime();
      const streak = isConsecutive ? lastCheckin.streak + 1 : 1;

      // 连续签到额外奖励
      let reward = 10;
      if (streak >= 7) reward = 25;
      else if (streak >= 5) reward = 20;
      else if (streak >= 3) reward = 15;

      const checkin = await this.prisma.dailyCheckin.create({
        data: { userId, checkinDate: today, streak, reward },
      });

      await this.prisma.user.update({
        where: { id: userId },
        data: {
          totalScore: { increment: reward },
          streakDays: streak,
          lastCheckinDate: today,
        },
      });

      return { ...checkin, isNewRecord: streak > 1 };
    }

    // 首次签到
    const reward = 10;
    const checkin = await this.prisma.dailyCheckin.create({
      data: { userId, checkinDate: today, streak: 1, reward },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        totalScore: { increment: reward },
        streakDays: 1,
        lastCheckinDate: today,
      },
    });

    return checkin;
  }

  async stats(userId: string) {
    const total = await this.prisma.dailyCheckin.count({ where: { userId } });
    const lastCheckin = await this.prisma.dailyCheckin.findFirst({
      where: { userId },
      orderBy: { checkinDate: 'desc' },
    });
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    return { total, currentStreak: lastCheckin?.streak ?? 0, streakDays: user?.streakDays ?? 0, lastCheckinDate: lastCheckin?.checkinDate ?? null };
  }
}
