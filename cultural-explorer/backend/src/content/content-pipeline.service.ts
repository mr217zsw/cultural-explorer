import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface DeepRegionContent {
  terrain: string;
  climate: string;
  rivers: { name: string; description: string }[];
  mountains: { name: string; description: string }[];
  historyTimeline: { year: string; title: string; description: string }[];
  famousPeople: { name: string; dynasty: string; title: string; description: string }[];
  intangibleHeritage: { name: string; level: string; category: string; description: string }[];
  festivals: string;
  cuisines: { name: string; category: string; description: string }[];
  dialects: string;
  ancientName?: string;
  foundingYear?: string;
  region?: string;
}

@Injectable()
export class ContentPipelineService {
  private readonly logger = new Logger(ContentPipelineService.name);
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(private config: ConfigService) {
    this.apiKey = this.config.getOrThrow<string>('DEEPSEEK_API_KEY');
    this.baseUrl = this.config.get<string>('DEEPSEEK_BASE_URL', 'https://api.deepseek.com');
  }

  /**
   * 一次性生成地区完整深度内容
   */
  async generateRegionContent(region: { name: string; capital?: string; area?: string }): Promise<DeepRegionContent> {
    this.logger.log(`Generating deep content for: ${region.name}`);

    const prompt = `
你是一位中国地理文化专家。请为"${region.name}${region.capital ? `（省会：${region.capital}）` : ''}"生成以下文化内容。以JSON格式输出，不要加任何其他内容。

要求：
- 内容必须基于真实的地理、历史和文化事实
- 描述生动、有画面感，适合大众阅读
- 每个地区的特色节假曰至少描述2-3个
- 非物质文化遗产列出最知名的3-5项
- 历史名人列出5-7位

JSON格式：
{
  "terrain": "地形地貌描述（150字）",
  "climate": "气候特征（100字）",
  "rivers": [{ "name": "河流名称", "description": "一句话描述" }],
  "mountains": [{ "name": "山脉名称", "description": "一句话描述" }],
  "historyTimeline": [{ "year": "年份", "title": "事件标题", "description": "一句话描述" }],
  "famousPeople": [{ "name": "姓名", "dynasty": "朝代/时代", "title": "头衔", "description": "一句话介绍" }],
  "intangibleHeritage": [{ "name": "非遗名称", "level": "国家级/省级", "category": "分类", "description": "一句话描述" }],
  "festivals": "特色节日介绍（200字）",
  "cuisines": [{ "name": "美食名称", "category": "主食/小吃/菜肴/饮品", "description": "一句话描述" }],
  "dialects": "方言特色介绍（80字）",
  "ancientName": "古称",
  "foundingYear": "建城年份",
  "region": "华东/华北/华南/西南/西北/东北之一"
}`;

    try {
      const response = await axios.post(
        `${this.baseUrl}/v1/chat/completions`,
        {
          model: 'deepseek-chat',
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7,
          max_tokens: 4096,
          response_format: { type: 'json_object' },
        },
        { headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' } },
      );

      const content = response.data.choices[0].message.content;
      return JSON.parse(content) as DeepRegionContent;
    } catch (err) {
      this.logger.error(`Content generation failed for ${region.name}: ${err.message}`);
      throw err;
    }
  }
}
