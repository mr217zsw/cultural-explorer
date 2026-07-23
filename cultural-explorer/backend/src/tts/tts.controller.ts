import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TTSService } from './tts.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../common/storage.service';

@Controller('audio')
export class TTSController {
  constructor(
    private readonly tts: TTSService,
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  @Post('generate')
  @UseGuards(JwtAuthGuard)
  async generate(@Body() body: { regionId: string; short?: boolean }) {
    const region = await this.prisma.region.findUnique({
      where: { id: body.regionId },
      select: { id: true, name: true, description: true, geography: true, history: true, culture: true },
    });
    if (!region) throw new Error('地区不存在');

    const text = body.short
      ? `${region.name}——${(region.description || '').slice(0, 200)}`
      : `${region.name}。${region.description || ''}。${region.geography || ''}。${region.history || ''}。${region.culture || ''}`;

    const audioBuffer = await this.tts.generate(text);
    const url = await this.storage.uploadAudio(audioBuffer, `${body.regionId}-${body.short ? 'short' : 'full'}.mp3`, 'audio');

    await this.prisma.region.update({
      where: { id: body.regionId },
      data: body.short ? { audioShort: url } : { audioGuide: url },
    });

    return { url, duration: body.short ? 'short' : 'full' };
  }
}
