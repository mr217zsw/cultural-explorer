import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { CurrentUser } from '../common/current-user.decorator';
import { OptionalAuthGuard } from '../common/optional-auth.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RegionsService } from './regions.service';

class RegionQuery {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit = 20;
  @IsOptional() @IsString() keyword?: string;
  @IsOptional() @IsString() sort?: string;
}

@Controller('regions')
export class RegionsController {
  constructor(private readonly regions: RegionsService) {}

  @Get() @UseGuards(OptionalAuthGuard)
  list(@Query() query: RegionQuery, @CurrentUser() user?: { sub: string }) { return this.regions.list(query, user?.sub); }

  @Get('random') random() { return this.regions.random(); }

  @Get(':id') @UseGuards(OptionalAuthGuard)
  detail(@Param('id') id: string, @CurrentUser() user?: { sub: string }) { return this.regions.detail(id, user?.sub); }

  @Get(':id/landmarks') landmarks(@Param('id') id: string) { return this.regions.landmarks(id); }

  @Get(':id/questions') questions(@Param('id') id: string) { return this.regions.questions(id); }

  @Post(':id/favorite') @UseGuards(JwtAuthGuard)
  favorite(@Param('id') id: string, @CurrentUser() user: { sub: string }) { return this.regions.toggleFavorite(id, user.sub); }
}

