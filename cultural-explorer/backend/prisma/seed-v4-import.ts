/**
 * v4.0 种子数据导入器
 * 读取 seed-v4-generate.ts 生成的 JSON，写入 PostgreSQL
 *
 * 前置条件: 已运行 npx tsx prisma/seed-v4-generate.ts 生成 JSON
 * 运行方式: npx tsx prisma/seed-v4-import.ts
 */

import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
// Prisma 原生读取 .env，无需 dotenv

const prisma = new PrismaClient();
const DATA_PATH = path.join(__dirname, 'seed-v4-output.json');

if (!fs.existsSync(DATA_PATH)) {
  console.error(`❌ 数据文件不存在: ${DATA_PATH}`);
  console.error('请先运行: npx tsx prisma/seed-v4-generate.ts');
  process.exit(1);
}

const ALL_DATA: Record<string, any> = JSON.parse(fs.readFileSync(DATA_PATH, 'utf-8'));

async function main() {
  const regionKeys = Object.keys(ALL_DATA).filter(k => !k.endsWith('_questions'));
  console.log(`📦 准备导入 ${regionKeys.length} 个地区...\n`);

  for (let i = 0; i < regionKeys.length; i++) {
    const key = regionKeys[i];
    const content = ALL_DATA[key];
    const questions = ALL_DATA[key + '_questions'] || [];
    const name = content.name;

    // 检查是否已存在
    const existing = await prisma.region.findUnique({ where: { name } });
    if (existing && existing.foundingYear) {
      console.log(`[${i + 1}/${regionKeys.length}] ⏭ ${name} 已有深度数据，跳过`);
      continue;
    }

    console.log(`[${i + 1}/${regionKeys.length}] 📝 ${name}...`);

    try {
      // 1. Upsert Region
      const region = await prisma.region.upsert({
        where: { name },
        create: {
          name: content.name,
          shortName: content.shortName,
          capital: content.capital,
          description: content.description || '',
          geography: content.geography || '',
          history: content.history || '',
          culture: content.culture || '',
          terrain: content.terrain || '',
          climate: content.climate || '',
          rivers: Array.isArray(content.rivers) ? content.rivers.map((r: any) => `${r.name}:${r.description}`).join('|') : '',
          mountains: Array.isArray(content.mountains) ? content.mountains.map((r: any) => `${r.name}:${r.description}`).join('|') : '',
          festivals: content.festivals || '',
          dialects: content.dialects || '',
          cuisine: Array.isArray(content.cuisines) ? content.cuisines.map((c: any) => c.name).join('、') : '',
          ancientName: content.ancientName || '',
          foundingYear: String(content.foundingYear || ''),
          region: content.regionGroup || '',
          famousPeople: content.famousPeople || [],
          historyTimeline: content.historyTimeline || [],
          sortOrder: i,
          area: String(content.area || ''),
          population: String(content.population || ''),
        },
        update: {
          terrain: content.terrain || '',
          climate: content.climate || '',
          rivers: Array.isArray(content.rivers) ? content.rivers.map((r: any) => `${r.name}:${r.description}`).join('|') : '',
          mountains: Array.isArray(content.mountains) ? content.mountains.map((r: any) => `${r.name}:${r.description}`).join('|') : '',
          festivals: content.festivals || '',
          dialects: content.dialects || '',
          cuisine: Array.isArray(content.cuisines) ? content.cuisines.map((c: any) => c.name).join('、') : '',
          ancientName: content.ancientName || '',
          foundingYear: String(content.foundingYear || ''),
          region: content.regionGroup || '',
          famousPeople: content.famousPeople || [],
          historyTimeline: content.historyTimeline || [],
          area: String(content.area || ''),
          population: String(content.population || ''),
        },
      });

      // 2. Chapters
      const chapterDefs = [
        { title: '印象·初见', contentKey: 'description', subtitle: '了解这片土地的第一印象' },
        { title: '地理·风物', contentKey: 'geography', subtitle: '山川河流与气候特征' },
        { title: '历史·时光', contentKey: 'history', subtitle: '岁月长河中的印记' },
        { title: '文化·传承', contentKey: 'culture', subtitle: '非遗技艺与民俗风情' },
      ];
      await prisma.chapter.deleteMany({ where: { regionId: region.id } });
      for (let j = 0; j < chapterDefs.length; j++) {
        const def = chapterDefs[j];
        await prisma.chapter.create({
          data: { regionId: region.id, title: def.title, subtitle: def.subtitle, content: content[def.contentKey] || '', sortOrder: j },
        });
      }

      // 3. TimelineEvents
      if (content.historyTimeline?.length) {
        await prisma.timelineEvent.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.historyTimeline.length; j++) {
          const ev = content.historyTimeline[j];
          await prisma.timelineEvent.create({
            data: { regionId: region.id, year: ev.year, title: ev.title, description: ev.description || '', sortOrder: j },
          });
        }
      }

      // 4. Cuisines
      if (content.cuisines?.length) {
        await prisma.cuisine.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.cuisines.length; j++) {
          const c = content.cuisines[j];
          await prisma.cuisine.create({
            data: { regionId: region.id, name: c.name, category: c.category, description: c.description || '', sortOrder: j },
          });
        }
      }

      // 5. IntangibleHeritage
      if (content.intangibleHeritage?.length) {
        await prisma.intangibleHeritage.deleteMany({ where: { regionId: region.id } });
        for (let j = 0; j < content.intangibleHeritage.length; j++) {
          const ih = content.intangibleHeritage[j];
          await prisma.intangibleHeritage.create({
            data: { regionId: region.id, name: ih.name, level: ih.level, category: ih.category, description: ih.description || '', sortOrder: j },
          });
        }
      }

      // 6. Questions — 删除旧的重新导入
      if (questions.length > 0) {
        await prisma.question.deleteMany({ where: { regionId: region.id } });
        await prisma.question.createMany({
          data: questions.map((q: any, qIdx: number) => {
            const isMulti = q.type === 'multiple';
            const isTF = q.type === 'truefalse';
            const ans = Array.isArray(q.correctAnswer) ? q.correctAnswer : [q.correctAnswer ?? 0];
            const base: any = {
              regionId: region.id,
              question: q.question,
              options: q.options || [],
              type: q.type || 'single',
              difficulty: q.difficulty || 1,
              explanation: q.explanation || '',
              category: q.tags?.[0] || 'culture',
              tags: q.tags || [],
              sortOrder: qIdx,
            };
            if (isTF) {
              return { ...base, correctAnswer: ans[0], correctBoolean: q.correctAnswer === 0 };
            }
            if (isMulti) {
              return { ...base, correctAnswer: ans[0], correctAnswers: ans };
            }
            return { ...base, correctAnswer: ans[0] };
          }),
        });
      }

      console.log(`   ✅ 章节${chapterDefs.length} | 时间轴${content.historyTimeline?.length || 0} | 美食${content.cuisines?.length || 0} | 非遗${content.intangibleHeritage?.length || 0} | 题目${questions.length}`);
    } catch (err: any) {
      console.error(`   ❌ ${name} 失败: ${err.message}`);
    }
  }

  const total = await prisma.region.count({ where: { foundingYear: { not: null } } });
  console.log(`\n🎉 导入完成！${total} 个地区拥有深度数据`);
  await prisma.$disconnect();
}

main();
