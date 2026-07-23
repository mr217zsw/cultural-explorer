import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class TTSService {
  private readonly logger = new Logger(TTSService.name);
  private readonly apiKey: string;
  private readonly model: string;

  constructor(private config: ConfigService) {
    this.apiKey = this.config.getOrThrow<string>('DASHSCOPE_API_KEY');
    this.model = this.config.get<string>('BAILIAN_TTS_MODEL', 'sambert-zhichu-v1');
  }

  /**
   * 生成 AI 配音音频（通义万相 TTS）
   * @returns 音频文件的 Buffer
   */
  async generate(text: string, voice?: string): Promise<Buffer> {
    const model = voice || this.model;
    this.logger.log(`Generating TTS audio (${text.length} chars, model: ${model})`);

    try {
      const response = await axios.post(
        'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2speech/stream-synthesis',
        {
          model,
          input: { text },
          parameters: { text_type: 'PlainText', rate: 0, pitch: 0, volume: 50 },
        },
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
            'X-DashScope-Async': 'enable',
          },
        },
      );

      // 提交异步任务
      const taskId = response.data?.output?.task_id;
      if (!taskId) throw new Error(`TTS task creation failed: ${JSON.stringify(response.data)}`);

      // 轮询等待任务完成
      const audioUrl = await this.pollTask(taskId);
      const audioResponse = await axios.get(audioUrl, { responseType: 'arraybuffer' });
      return Buffer.from(audioResponse.data);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`TTS generation failed: ${message}`);
      throw err;
    }
  }

  /**
   * 分段生成配音（长文本分段 + 拼接）
   */
  async generateSegmented(text: string, segmentSize = 500): Promise<Buffer> {
    const segments: string[] = [];
    for (let i = 0; i < text.length; i += segmentSize) {
      segments.push(text.slice(i, i + segmentSize));
    }
    this.logger.log(`TTS segmented into ${segments.length} chunks`);

    const buffers: Buffer[] = [];
    for (let i = 0; i < segments.length; i++) {
      if (i > 0) await this.sleep(1000); // API 限流
      buffers.push(await this.generate(segments[i]));
    }
    return Buffer.concat(buffers);
  }

  private async pollTask(taskId: string): Promise<string> {
    for (let i = 0; i < 60; i++) {
      const resp = await axios.get(
        `https://dashscope.aliyuncs.com/api/v1/tasks/${taskId}`,
        { headers: { Authorization: `Bearer ${this.apiKey}` } },
      );
      const status = resp.data?.output?.task_status;
      if (status === 'SUCCEEDED') {
        return resp.data.output.results[0].url;
      }
      if (status === 'FAILED') throw new Error(`TTS task failed: ${resp.data.output?.message}`);
      await this.sleep(2000);
    }
    throw new Error('TTS task timeout');
  }

  private sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }
}
