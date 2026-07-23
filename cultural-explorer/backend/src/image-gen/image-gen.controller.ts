import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ImageGenService } from './image-gen.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('image')
export class ImageGenController {
  constructor(
    private readonly imageGen: ImageGenService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('generate-cover')
  @UseGuards(JwtAuthGuard)
  async generateCover(@Body() body: { regionId: string }) {
    const region = await this.prisma.region.findUnique({
      where: { id: body.regionId },
      include: { landmarks: { take: 2, orderBy: { sortOrder: 'asc' } } },
    });
    if (!region) throw new Error('地区不存在');

    const landmark = region.landmarks[0]?.name || '';
    const prompt = this.imageGen.generateCoverImagePrompt(region.name, landmark);
    const imageUrl = await this.imageGen.generate(prompt);

    await this.prisma.region.update({
      where: { id: body.regionId },
      data: { heroImage: imageUrl },
    });

    return { imageUrl };
  }
}
