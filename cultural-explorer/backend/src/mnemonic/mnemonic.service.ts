import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../common/redis.service';

@Injectable()
export class MnemonicService {
  private readonly logger = new Logger(MnemonicService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly redis: RedisService,
  ) {}

  async getOrCreate(regionId: string) {
    const cached = await this.prisma.mnemonic.findUnique({ where: { regionId } });
    return cached ?? this.generate(regionId, '七言口诀');
  }

  async getWithCache(regionId: string) {
    // 1. 查Redis缓存
    const redisKey = `mnemonic:${regionId}`;
    const redisCached = await this.redis.get<string>(redisKey);
    if (redisCached) {
      return { content: redisCached, style: '七言口诀', generatedAt: new Date(), source: 'redis' as const };
    }

    // 2. 查数据库
    const dbCached = await this.prisma.mnemonic.findUnique({ where: { regionId } });
    if (dbCached) {
      await this.redis.set(redisKey, dbCached.content, 2592000); // 30天
      return { content: dbCached.content, style: dbCached.style, generatedAt: dbCached.generatedAt, source: 'db' as const };
    }

    // 3. 生成新的
    const result = await this.generate(regionId, '七言口诀');
    await this.redis.set(redisKey, result.content, 2592000);
    return { ...result, generatedAt: result.generatedAt, source: 'ai' as const };
  }

  async generate(regionId: string, style: string, force = false) {
    if (!force) {
      const cached = await this.prisma.mnemonic.findUnique({ where: { regionId } });
      if (cached) return cached;
    }

    const region = await this.prisma.region.findUnique({
      where: { id: regionId },
      include: { landmarks: { take: 4, orderBy: { sortOrder: 'asc' } } },
    });
    if (!region) throw new NotFoundException('地区不存在');

    const apiKey = this.config.get<string>('DEEPSEEK_API_KEY');
    let content = this.buildFallbackMnemonic(region);

    if (apiKey) {
      try {
        const response = await fetch(
          `${this.config.get('DEEPSEEK_BASE_URL', 'https://api.deepseek.com')}/chat/completions`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
            body: JSON.stringify({
              model: 'deepseek-chat',
              temperature: 0.7,
              max_tokens: 300,
              messages: [
                {
                  role: 'system',
                  content: '你是中国地理文化教师。请根据提供的信息创作朗朗上口、事实准确、适合记忆的口诀，四句七言，押韵工整。只输出口诀正文，不要任何解释。',
                },
                {
                  role: 'user',
                  content: `请为"${region.name}"创作记忆口诀。\n省会：${region.capital}\n地理：${region.geography.slice(0, 120)}\n历史：${region.history.slice(0, 120)}\n文化：${region.culture.slice(0, 120)}\n代表地标：${region.landmarks.map((l) => l.name).join('、')}`,
                },
              ],
            }),
          },
        );

        if (response.ok) {
          const result = (await response.json()) as { choices?: { message?: { content?: string } }[] };
          const aiContent = result.choices?.[0]?.message?.content?.trim();
          if (aiContent) content = aiContent;
        } else {
          this.logger.warn(`DeepSeek API error: ${response.status} ${response.statusText}`);
        }
      } catch (e) {
        this.logger.warn(`DeepSeek API call failed: ${e}`);
      }
    }

    // 写入数据库
    const mnemonic = await this.prisma.mnemonic.upsert({
      where: { regionId },
      update: { content, style, generationCount: { increment: 1 }, generatedAt: new Date() },
      create: { regionId, content, style },
    });

    // 写入Redis（30天）
    await this.redis.set(`mnemonic:${regionId}`, content, 2592000);

    return mnemonic;
  }

  private buildFallbackMnemonic(region: { name: string; shortName?: string | null; capital?: string | null; landmarks: { name: string }[] }): string {
    const landmarkNames = region.landmarks.map((l) => l.name).join('、') || '山河风光';
    return `${region.name}${region.shortName ? `(${region.shortName})` : ''} 好风光，${region.capital ?? region.name} 古城藏。${landmarkNames} 美名扬，华夏文明万年长。`;
  }

  async share(regionId: string) {
    const region = await this.prisma.region.findUnique({
      where: { id: regionId },
      select: { name: true, coverImage: true },
    });
    if (!region) throw new NotFoundException('地区不存在');
    const mnemonic = await this.getOrCreate(regionId);
    return {
      content: `我在"华夏文化探索"学习了${region.name}：\n${mnemonic.content}`,
      shareImage: region.coverImage,
    };
  }
}
