/**
 * v4.0 种子数据生成器 —— 批量生成 34 个省级行政区的深度内容
 * 使用 DeepSeek API 一次性生成结构化数据，写入 Chapter/Timeline/Cuisine/Heritage 表
 *
 * 运行方式: npx tsx prisma/seed-v4.ts
 */

import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();
const API_KEY = process.env.DEEPSEEK_API_KEY!;
const BASE_URL = process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com';

/** 中国 34 个省级行政区 */
const ALL_REGIONS = [
  '北京市', '天津市', '河北省', '山西省', '内蒙古自治区',
  '辽宁省', '吉林省', '黑龙江省',
  '上海市', '江苏省', '浙江省', '安徽省', '福建省', '江西省', '山东省',
  '河南省', '湖北省', '湖南省', '广东省', '广西壮族自治区', '海南省',
  '重庆市', '四川省', '贵州省', '云南省', '西藏自治区',
  '陕西省', '甘肃省', '青海省', '宁夏回族自治区', '新疆维吾尔自治区',
  '台湾省', '香港特别行政区', '澳门特别行政区',
];

async function generateContent(name: string): Promise<any> {
  const prompt = `你是一位中国地理文化专家。请为"${name}"生成文化内容。严格以JSON格式输出，不要加任何其他内容。格式：
{
  "description": "简介（120字）",
  "geography": "地理介绍（200字）",
  "history": "历史介绍（200字）",
  "culture": "文化介绍（200字）",
  "terrain": "地形地貌（150字）",
  "climate": "气候特征（100字）",
  "rivers": [{ "name": "名", "description": "描" }],
  "mountains": [{ "name": "名", "description": "描" }],
  "historyTimeline": [{ "year": "年份", "title": "事件", "description": "描述" }],
  "famousPeople": [{ "name": "姓名", "dynasty": "朝代", "title": "头衔", "description": "介绍" }],
  "intangibleHeritage": [{ "name": "非遗名称", "level": "国家级/省级", "category": "传统技艺/音乐/美术/舞蹈/戏剧/民俗", "description": "描述" }],
  "festivals": "特色节日（100字）",
  "cuisines": [{ "name": "美食", "category": "主食/小吃/菜肴/饮品", "description": "描述" }],
  "dialects": "方言特色（60字）",
  "ancientName": "古称",
  "foundingYear": "建城年份",
  "regionGroup": "华东/华北/华南/西南/西北/东北之一"
}
要求：内容真实，描述生动，大众化，每个历史时间轴至少10条，名人至少5位，非遗至少3项，美食至少3道。`;

  const resp = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7, max_tokens: 4096,
      response_format: { type: 'json_object' },
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`HTTP ${resp.status}: ${errText.slice(0, 200)}`);
  }

  const json: any = await resp.json();
  if (!json.choices || !json.choices[0]?.message?.content) {
    throw new Error(`API response missing content: ${JSON.stringify(json).slice(0, 300)}`);
  }
  return JSON.parse(json.choices[0].message.content);
}

function shortName(name: string): string {
  const m: Record<string, string> = {
    '北京市': '京', '天津市': '津', '河北省': '冀', '山西省': '晋', '内蒙古自治区': '蒙',
    '辽宁省': '辽', '吉林省': '吉', '黑龙江省': '黑',
    '上海市': '沪', '江苏省': '苏', '浙江省': '浙', '安徽省': '皖', '福建省': '闽',
    '江西省': '赣', '山东省': '鲁',
    '河南省': '豫', '湖北省': '鄂', '湖南省': '湘', '广东省': '粤', '广西壮族自治区': '桂',
    '海南省': '琼',
    '重庆市': '渝', '四川省': '川', '贵州省': '黔', '云南省': '滇', '西藏自治区': '藏',
    '陕西省': '陕', '甘肃省': '甘', '青海省': '青', '宁夏回族自治区': '宁',
    '新疆维吾尔自治区': '新', '台湾省': '台', '香港特别行政区': '港', '澳门特别行政区': '澳',
  };
  return m[name] || name.slice(0, 2);
}

function capital(name: string): string {
  const m: Record<string, string> = {
    '北京市': '北京', '天津市': '天津', '河北省': '石家庄', '山西省': '太原',
    '内蒙古自治区': '呼和浩特',
    '辽宁省': '沈阳', '吉林省': '长春', '黑龙江省': '哈尔滨',
    '上海市': '上海', '江苏省': '南京', '浙江省': '杭州', '安徽省': '合肥',
    '福建省': '福州', '江西省': '南昌', '山东省': '济南',
    '河南省': '郑州', '湖北省': '武汉', '湖南省': '长沙', '广东省': '广州',
    '广西壮族自治区': '南宁', '海南省': '海口',
    '重庆市': '重庆', '四川省': '成都', '贵州省': '贵阳', '云南省': '昆明',
    '西藏自治区': '拉萨',
    '陕西省': '西安', '甘肃省': '兰州', '青海省': '西宁', '宁夏回族自治区': '银川',
    '新疆维吾尔自治区': '乌鲁木齐', '台湾省': '台北', '香港特别行政区': '香港',
    '澳门特别行政区': '澳门',
  };
  return m[name] || '';
}

async function main() {
  console.log(`🚀 开始批量生成 ${ALL_REGIONS.length} 个地区内容...\n`);

  for (let i = 0; i < ALL_REGIONS.length; i++) {
    const name = ALL_REGIONS[i];
    const displayName = name.replace(/市|省|自治区|特别行政区/g, '');

    // 跳过已存在的
    const existing = await prisma.region.findUnique({ where: { name: displayName } });
    if (existing && existing.foundingYear) {
      console.log(`[${i + 1}/${ALL_REGIONS.length}] ⏭ ${name} 已有深度数据，跳过`);
      continue;
    }

    console.log(`[${i + 1}/${ALL_REGIONS.length}] 🤖 正在生成 ${name}...`);

    try {
      const content = await generateContent(name);
      const cap = capital(name);
      const sn = shortName(name);

      const data = {
        shortName: sn,
        capital: cap,
        area: content.area || '',
        population: content.population || '',
        description: content.description || '',
        geography: content.geography || '',
        history: content.history || '',
        culture: content.culture || '',
        terrain: content.terrain || '',
        climate: content.climate || '',
        rivers: content.rivers?.map((r: any) => `${r.name}:${r.description}`).join('|') || '',
        mountains: content.mountains?.map((r: any) => `${r.name}:${r.description}`).join('|') || '',
        festivals: content.festivals || '',
        dialects: content.dialects || '',
        cuisine: content.cuisines?.map((c: any) => c.description).join('；') || '',
        ancientName: content.ancientName || '',
        foundingYear: content.foundingYear || '',
        region: content.regionGroup || '',
        famousPeople: content.famousPeople || [],
        historyTimeline: content.historyTimeline || [],
        gallery: [],
        sortOrder: i,
      };

      // Upsert Region
      await prisma.region.upsert({
        where: { name: displayName },
        create: { name: displayName, ...data },
        update: data,
      });

      const region = await prisma.region.findUniqueOrThrow({ where: { name: displayName } });

      // 写入 Chapters
      const chapterDefs = [
        { title: '印象·初见', subtitle: '了解这片土地的第一印象', contentKey: 'description' },
        { title: '地理·风物', subtitle: '山川河流与气候特征', contentKey: 'geography' },
        { title: '历史·时光', subtitle: '岁月长河中的印记', contentKey: 'history' },
        { title: '文化·传承', subtitle: '非遗技艺与民俗风情', contentKey: 'culture' },
        { title: '探索·足迹', subtitle: '走进这片神奇的土地', contentKey: 'geography' },
      ];

      for (let j = 0; j < chapterDefs.length; j++) {
        const def = chapterDefs[j];
        await prisma.chapter.deleteMany({ where: { regionId: region.id, sortOrder: j } });
        await prisma.chapter.create({
          data: {
            regionId: region.id,
            title: def.title,
            subtitle: def.subtitle,
            content: (data as any)[def.contentKey] || '',
            sortOrder: j,
          },
        });
      }

      // 写入 TimelineEvents
      if (content.historyTimeline?.length) {
        await prisma.timelineEvent.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.historyTimeline.length; j++) {
          const ev = content.historyTimeline[j];
          await prisma.timelineEvent.create({
            data: {
              regionId: region.id,
              year: ev.year,
              title: ev.title,
              description: ev.description,
              sortOrder: j,
            },
          });
        }
      }

      // 写入 Cuisines
      if (content.cuisines?.length) {
        await prisma.cuisine.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.cuisines.length; j++) {
          const c = content.cuisines[j];
          await prisma.cuisine.create({
            data: { regionId: region.id, name: c.name, category: c.category, description: c.description, sortOrder: j },
          });
        }
      }

      // 写入 IntangibleHeritage
      if (content.intangibleHeritage?.length) {
        await prisma.intangibleHeritage.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.intangibleHeritage.length; j++) {
          const ih = content.intangibleHeritage[j];
          await prisma.intangibleHeritage.create({
            data: { regionId: region.id, name: ih.name, level: ih.level, category: ih.category, description: ih.description, sortOrder: j },
          });
        }
      }

      // 确保有基本题目
      const questionCount = await prisma.question.count({ where: { regionId: region.id } });
      if (questionCount === 0) {
        await prisma.question.createMany({
          data: [
            { regionId: region.id, question: `${displayName}的简称是？`, options: ['A', 'B', 'C', sn], correctAnswer: 3, difficulty: 1, category: 'geography', explanation: `${displayName}简称"${sn}"`, sortOrder: 0, tags: ['地理', '简称'] },
            { regionId: region.id, question: `${displayName}的省会是？`, options: ['A', cap, 'C', 'D'], correctAnswer: 1, difficulty: 1, category: 'geography', explanation: `${displayName}省会是${cap}`, sortOrder: 1, tags: ['地理', '省会'] },
          ],
        });
      }

      console.log(`   ✅ 章节${chapterDefs.length} | 时间轴${content.historyTimeline?.length || 0} | 美食${content.cuisines?.length || 0} | 非遗${content.intangibleHeritage?.length || 0}`);
    } catch (err: any) {
      console.error(`   ❌ ${name} 失败: ${err.message}`);
    }

    if (i < ALL_REGIONS.length - 1) {
      await new Promise(r => setTimeout(r, 1500)); // API 限流
    }
  }

  console.log(`\n🎉 全部完成! ${ALL_REGIONS.length} 个地区种子数据已准备就绪`);
  await prisma.$disconnect();
}

main();
