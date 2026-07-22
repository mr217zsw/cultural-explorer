import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { CurrentUser } from '../common/current-user.decorator';
import { OptionalAuthGuard } from '../common/optional-auth.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RegionsService } from './regions.service';
import { ChapterService } from '../chapter/chapter.service';
import { TimelineEventService } from '../timeline-event/timeline-event.service';
import { CuisineService } from '../cuisine/cuisine.service';
import { HeritageService } from '../heritage/heritage.service';

class RegionQuery {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit = 20;
  @IsOptional() @IsString() keyword?: string;
  @IsOptional() @IsString() sort?: string;
}

@Controller('regions')
export class RegionsController {
  constructor(
    private readonly regions: RegionsService,
    private readonly chapterService: ChapterService,
    private readonly timelineService: TimelineEventService,
    private readonly cuisineService: CuisineService,
    private readonly heritageService: HeritageService,
  ) {}

  @Get() @UseGuards(OptionalAuthGuard)
  list(@Query() query: RegionQuery, @CurrentUser() user?: { sub: string }) {
    return this.regions.list(query, user?.sub);
  }

  @Get('random') random() { return this.regions.random(); }

  @Get(':id') @UseGuards(OptionalAuthGuard)
  detail(@Param('id') id: string, @CurrentUser() user?: { sub: string }) {
    return this.regions.detail(id, user?.sub);
  }

  @Get(':id/landmarks') landmarks(@Param('id') id: string) { return this.regions.landmarks(id); }
  @Get(':id/questions') questions(@Param('id') id: string) { return this.regions.questions(id); }

  @Post(':id/favorite') @UseGuards(JwtAuthGuard)
  favorite(@Param('id') id: string, @CurrentUser() user: { sub: string }) {
    return this.regions.toggleFavorite(id, user.sub);
  }

  // ===== v4.0 新增端点 =====
  @Get(':id/chapters') chapters(@Param('id') id: string) { return this.chapterService.findByRegion(id); }
  @Get(':id/timeline') timeline(@Param('id') id: string) { return this.timelineService.findByRegion(id); }
  @Get(':id/cuisine') cuisine(@Param('id') id: string) { return this.cuisineService.findByRegion(id); }
  @Get(':id/heritage') heritage(@Param('id') id: string) { return this.heritageService.findByRegion(id); }
}
