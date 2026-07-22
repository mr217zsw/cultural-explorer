import { Controller, Get, Param } from '@nestjs/common';
import { ChapterService } from './chapter.service';

@Controller('chapters')
export class ChapterController {
  constructor(private readonly chapterService: ChapterService) {}

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.chapterService.findOne(id);
  }
}
