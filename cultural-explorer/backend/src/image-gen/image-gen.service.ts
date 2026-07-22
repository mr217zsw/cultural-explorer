import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class ImageGenService {
  private readonly logger = new Logger(ImageGenService.name);
  private readonly apiKey: string;
  private readonly model: string;

  constructor(private config: ConfigService) {
    this.apiKey = this.config.getOrThrow<string>('DASHSCOPE_API_KEY');
    this.model = this.config.get<string>('BAILIAN_IMAGE_MODEL', 'wanx-v1');
  }

  /**
   * 生成图片（通义万相 文生图）
   */
  async generate(prompt: string, negativePrompt?: string): Promise<string> {
    this.logger.log(`Generating image (prompt: ${prompt.slice(0, 100)}...)`);

    const response = await axios.post(
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis',
      {
        model: this.model,
        input: {
          prompt,
          negative_prompt: negativePrompt || '低质量, 模糊, 变形, 文字, 水印',
        },
        parameters: {
          n: 1,
          size: '1024*1024',
        },
      },
      {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
          'X-DashScope-Async': 'enable',
        },
      },
    );

    const taskId = response.data?.output?.task_id;
    if (!taskId) throw new Error(`Image gen task creation failed`);

    return this.pollTask(taskId);
  }

  /**
   * 生成地区封面图
   */
  generateCoverImagePrompt(regionName: string, landmark?: string, style = '中国风插画'): string {
    let prompt = `${regionName}，`;
    if (landmark) prompt += `${landmark}，`;
    prompt += `${style}，鲜艳，细节丰富，高质量，适合旅行App封面，无文字，无水印`;
    return prompt;
  }

  private async pollTask(taskId: string): Promise<string> {
    for (let i = 0; i < 90; i++) {
      const resp = await axios.get(
        `https://dashscope.aliyuncs.com/api/v1/tasks/${taskId}`,
        { headers: { Authorization: `Bearer ${this.apiKey}` } },
      );
      const status = resp.data?.output?.task_status;
      if (status === 'SUCCEEDED') {
        return resp.data.output.results[0].url;
      }
      if (status === 'FAILED') throw new Error(`Image gen failed: ${resp.data.output?.message}`);
      await this.sleep(3000);
    }
    throw new Error('Image gen task timeout');
  }

  private sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }
}
