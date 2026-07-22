import { Module } from '@nestjs/common';
import { ContentPipelineService } from './content-pipeline.service';

@Module({
  providers: [ContentPipelineService],
  exports: [ContentPipelineService],
})
export class ContentModule {}
