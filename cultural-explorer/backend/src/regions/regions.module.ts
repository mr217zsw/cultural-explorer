import { Module } from '@nestjs/common';
import { RegionsController } from './regions.controller';
import { RegionsService } from './regions.service';
import { ChapterModule } from '../chapter/chapter.module';
import { TimelineEventModule } from '../timeline-event/timeline-event.module';
import { CuisineModule } from '../cuisine/cuisine.module';
import { HeritageModule } from '../heritage/heritage.module';

@Module({
  imports: [ChapterModule, TimelineEventModule, CuisineModule, HeritageModule],
  controllers: [RegionsController],
  providers: [RegionsService],
  exports: [RegionsService],
})
export class RegionsModule {}
