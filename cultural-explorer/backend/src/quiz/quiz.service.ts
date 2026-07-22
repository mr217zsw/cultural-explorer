import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

type CompleteInput = { regionId: string; answers: { questionId: string; selectedIndex: number }[]; timeSpent?: number };

@Injectable()
export class QuizService {
  constructor(private readonly prisma: PrismaService) {}

  async start(regionId: string) {
    const questions = await this.prisma.question.findMany({ where: { regionId }, orderBy: { sortOrder: 'asc' }, select: { id: true, question: true, options: true, difficulty: true, category: true } });
    if (!questions.length) throw new NotFoundException('该地区暂无题目');
    return { sessionId: randomUUID(), questions };
  }

  async submit(questionId: string, selectedIndex: number) {
    const question = await this.prisma.question.findUnique({ where: { id: questionId } });
    if (!question) throw new NotFoundException('题目不存在');
    const correct = question.correctAnswer === selectedIndex;
    return { correct, correctIndex: question.correctAnswer, explanation: question.explanation, score: correct ? 20 : 0 };
  }

  async complete(userId: string, input: CompleteInput) {
    const questions = await this.prisma.question.findMany({ where: { regionId: input.regionId } });
    if (!questions.length) throw new NotFoundException('该地区暂无题目');
    const answerMap = new Map(input.answers.map((answer) => [answer.questionId, answer.selectedIndex]));
    const details = questions.map((question) => ({ questionId: question.id, selectedIndex: answerMap.get(question.id) ?? -1, correctIndex: question.correctAnswer, correct: answerMap.get(question.id) === question.correctAnswer }));
    const correctCount = details.filter((item) => item.correct).length;
    const accuracy = correctCount / questions.length;
    const isCompleted = accuracy >= 0.6;
    const baseScore = correctCount * 20;
    const oldRecord = await this.prisma.userRecord.findUnique({ where: { userId_regionId: { userId, regionId: input.regionId } } });
    const firstCompletion = isCompleted && !oldRecord?.isCompleted;
    const bonus = firstCompletion ? 20 : 0;
    const earnedScore = Math.max(0, baseScore + bonus - (oldRecord?.score ?? 0));

    await this.prisma.$transaction([
      this.prisma.userRecord.upsert({
        where: { userId_regionId: { userId, regionId: input.regionId } },
        update: { score: Math.max(baseScore + bonus, oldRecord?.score ?? 0), totalQuestions: questions.length, correctCount, wrongCount: questions.length - correctCount, timeSpent: input.timeSpent, isCompleted: oldRecord?.isCompleted || isCompleted, completedAt: firstCompletion ? new Date() : oldRecord?.completedAt, answers: details as Prisma.InputJsonValue },
        create: { userId, regionId: input.regionId, score: baseScore + bonus, totalQuestions: questions.length, correctCount, wrongCount: questions.length - correctCount, timeSpent: input.timeSpent, isCompleted, completedAt: isCompleted ? new Date() : null, answers: details as Prisma.InputJsonValue },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          totalScore: { increment: earnedScore },
          ...(firstCompletion ? { completedCount: { increment: 1 }, completedRegions: { push: input.regionId }, maxStreak: { increment: 1 } } : {}),
        },
      }),
    ]);
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return { isCompleted, totalScore: user.totalScore, correctCount, totalQuestions: questions.length, accuracy, reward: { earnedScore, bonus, badge: firstCompletion ? '🏯 文化行者' : null }, details };
  }

  records(userId: string, regionId?: string) {
    return this.prisma.userRecord.findMany({ where: { userId, ...(regionId ? { regionId } : {}) }, include: { region: { select: { name: true, shortName: true } } }, orderBy: { updatedAt: 'desc' } });
  }

  ranking(regionId: string, limit: number) {
    return this.prisma.userRecord.findMany({ where: { regionId, isCompleted: true }, take: Math.min(Math.max(limit, 1), 100), orderBy: [{ score: 'desc' }, { timeSpent: 'asc' }], select: { score: true, correctCount: true, timeSpent: true, completedAt: true, user: { select: { id: true, nickname: true, avatar: true } } } });
  }
}
