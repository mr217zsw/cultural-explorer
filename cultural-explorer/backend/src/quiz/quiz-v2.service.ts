import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../common/redis.service';

interface QuizSession {
  regionId: string;
  difficulty: number;
  questionIds: string[];
  currentIndex: number;
  lives: number;
  combo: number;
  score: number;
  answers: { questionId: string; isCorrect: boolean; score: number }[];
}

@Injectable()
export class QuizV2Service {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  /** 开始闯关 - 支持难度分级 */
  async start(userId: string, regionId: string, difficulty: number = 1) {
    const questions = await this.prisma.question.findMany({
      where: {
        regionId,
        difficulty: { lte: difficulty },
        type: { in: ['single', 'multiple', 'truefalse'] },
      },
      orderBy: { sortOrder: 'asc' },
    });

    if (questions.length === 0) throw new BadRequestException('该地区暂无题目');

    const shuffled = this.shuffle(questions).slice(0, 10);
    const session: QuizSession = {
      regionId,
      difficulty,
      questionIds: shuffled.map(q => q.id),
      currentIndex: 0,
      lives: 3,
      combo: 0,
      score: 0,
      answers: [],
    };

    await this.redis.set(`quiz:session:${userId}`, JSON.stringify(session), 3600);

    return {
      sessionId: userId,
      totalQuestions: shuffled.length,
      difficulty,
      lives: session.lives,
      questions: shuffled.map(q => ({
        id: q.id,
        type: q.type,
        question: q.question,
        options: q.options,
        difficulty: q.difficulty,
        timeLimit: this.getTimeLimit(q.difficulty),
        tags: q.tags || [],
      })),
    };
  }

  /** 逐题提交答案 */
  async submit(userId: string, questionId: string, answer: any) {
    const raw = await this.redis.get(`quiz:session:${userId}`);
    if (!raw) throw new BadRequestException('闯关会话已过期');
    const session: QuizSession = JSON.parse(raw);

    const question = await this.prisma.question.findUnique({ where: { id: questionId } });
    if (!question) throw new BadRequestException('题目不存在');

    const isCorrect = this.checkAnswer(question, answer);

    let score = 0;
    if (isCorrect) {
      session.combo++;
      const baseScore = this.getBaseScore(question.difficulty);
      const comboBonus = Math.floor(session.combo / 3) * 5;
      score = baseScore + comboBonus;
    } else {
      session.combo = 0;
      session.lives--;
    }
    session.score += score;
    session.answers.push({ questionId, isCorrect, score });
    session.currentIndex++;

    const isLast = session.currentIndex >= session.questionIds.length;
    const isGameOver = session.lives <= 0;

    if (isLast || isGameOver) {
      await this.complete(userId, session);
      await this.redis.del(`quiz:session:${userId}`);

      return {
        isCorrect,
        correctAnswer: isCorrect ? undefined : this.getRevealAnswer(question),
        explanation: question.explanation,
        score,
        combo: session.combo,
        lives: session.lives,
        totalScore: session.score,
        isGameOver: true,
        grade: this.calcGrade(session),
        isCompleted: isLast && !isGameOver,
        nextQuestion: undefined,
      };
    }

    await this.redis.set(`quiz:session:${userId}`, JSON.stringify(session), 3600);

    const nextQ = await this.prisma.question.findUnique({
      where: { id: session.questionIds[session.currentIndex] },
    });

    return {
      isCorrect,
      correctAnswer: isCorrect ? undefined : this.getRevealAnswer(question),
      explanation: question.explanation,
      score,
      combo: session.combo,
      lives: session.lives,
      totalScore: session.score,
      isGameOver: false,
      nextQuestion: nextQ ? {
        id: nextQ.id,
        type: nextQ.type,
        question: nextQ.question,
        options: nextQ.options,
        difficulty: nextQ.difficulty,
        timeLimit: this.getTimeLimit(nextQ.difficulty),
        tags: nextQ.tags || [],
      } : undefined,
    };
  }

  /** 完成闯关 - 写入数据库 */
  private async complete(userId: string, session: QuizSession) {
    const correctCount = session.answers.filter(a => a.isCorrect).length;
    const totalQuestions = session.questionIds.length;
    const questionIds = session.questionIds;

    await this.prisma.question.updateMany({
      where: { id: { in: questionIds } },
      data: { rightCount: { increment: correctCount }, wrongCount: { increment: totalQuestions - correctCount } },
    });

    const isCompleted = session.lives > 0;

    await this.prisma.userRecord.upsert({
      where: { userId_regionId: { userId, regionId: session.regionId } },
      create: {
        userId,
        regionId: session.regionId,
        score: session.score,
        totalQuestions,
        correctCount,
        wrongCount: totalQuestions - correctCount,
        isCompleted,
        completedAt: isCompleted ? new Date() : undefined,
        answers: session.answers as any,
      },
      update: {
        score: { set: session.score },
        totalQuestions: { set: totalQuestions },
        correctCount: { set: correctCount },
        wrongCount: { set: totalQuestions - correctCount },
        isCompleted: isCompleted || undefined,
        completedAt: isCompleted ? new Date() : undefined,
        answers: session.answers as any,
      },
    });

    if (isCompleted) {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      const completedRegions = [...(user!.completedRegions || [])];
      if (!completedRegions.includes(session.regionId)) completedRegions.push(session.regionId);

      const wasPerfect = correctCount === totalQuestions;
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          totalScore: { increment: session.score },
          completedCount: completedRegions.length,
          completedRegions,
          perfectCount: wasPerfect ? { increment: 1 } : undefined,
        },
      });
    }
  }

  /** 多题型答案校验 */
  private checkAnswer(question: any, answer: any): boolean {
    switch (question.type) {
      case 'single': return answer === question.correctAnswer;
      case 'multiple':
        return Array.isArray(answer) &&
          answer.length === question.correctAnswers.length &&
          answer.sort().every((v: number, i: number) => v === [...question.correctAnswers].sort()[i]);
      case 'truefalse': return answer === question.correctBoolean;
      default: return answer === question.correctAnswer;
    }
  }

  private getRevealAnswer(question: any): any {
    if (question.type === 'single') return question.correctAnswer;
    if (question.type === 'multiple') return question.correctAnswers;
    if (question.type === 'truefalse') return question.correctBoolean;
    return question.correctAnswer;
  }

  private calcGrade(session: QuizSession): string {
    const total = session.questionIds.length;
    const correct = session.answers.filter(a => a.isCorrect).length;
    const rate = correct / total;
    if (rate >= 0.95) return 'S';
    if (rate >= 0.85) return 'A';
    if (rate >= 0.70) return 'B';
    return 'C';
  }

  private getTimeLimit(d: number): number {
    return { 1: 30, 2: 25, 3: 20, 4: 15, 5: 10 }[d] ?? 30;
  }

  private getBaseScore(d: number): number {
    return d * 10 + 10;
  }

  private shuffle<T>(arr: T[]): T[] {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }
}
