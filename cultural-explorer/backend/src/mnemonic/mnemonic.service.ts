import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MnemonicService {
  constructor(private readonly prisma: PrismaService, private readonly config: ConfigService) {}

  async getOrCreate(regionId: string) {
    const cached = await this.prisma.mnemonic.findUnique({ where: { regionId } });
    return cached ?? this.generate(regionId, '七言口诀');
  }

  async generate(regionId: string, style: string, force = false) {
    if (!force) {
      const cached = await this.prisma.mnemonic.findUnique({ where: { regionId } });
      if (cached) return cached;
    }
    const region = await this.prisma.region.findUnique({ where: { id: regionId }, include: { landmarks: { take: 4, orderBy: { sortOrder: 'asc' } } } });
    if (!region) throw new NotFoundException('地区不存在');
    const apiKey = this.config.get<string>('DEEPSEEK_API_KEY');
    let content = `${region.name}${region.shortName ?? ''}风物长，${region.capital ?? region.name}古今藏。${region.landmarks.map((item) => item.name).join('、')}留胜迹，山河人文记心房。`;
    if (apiKey) {
      const response = await fetch(`${this.config.get('DEEPSEEK_BASE_URL', 'https://api.deepseek.com')}/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
        body: JSON.stringify({
          model: 'deepseek-chat', temperature: 0.7, max_tokens: 300,
          messages: [
            { role: 'system', content: '你是中国地理文化教师。生成朗朗上口、事实准确、适合记忆的口诀，只输出口诀正文。' },
            { role: 'user', content: `请以${style}介绍${region.name}。省会：${region.capital}；地理：${region.geography}；历史：${region.history}；文化：${region.culture}；地标：${region.landmarks.map((item) => item.name).join('、')}。` },
          ],
        }),
      });
      if (response.ok) {
        const result = await response.json() as { choices?: { message?: { content?: string } }[] };
        content = result.choices?.[0]?.message?.content?.trim() || content;
      }
    }
    return this.prisma.mnemonic.upsert({
      where: { regionId },
      update: { content, style, generationCount: { increment: 1 }, generatedAt: new Date() },
      create: { regionId, content, style },
    });
  }

  async share(regionId: string) {
    const region = await this.prisma.region.findUnique({ where: { id: regionId }, select: { name: true, coverImage: true } });
    if (!region) throw new NotFoundException('地区不存在');
    const mnemonic = await this.getOrCreate(regionId);
    return { content: `我在“华夏文化探索”学习了${region.name}：\n${mnemonic.content}`, shareImage: region.coverImage };
  }
}

