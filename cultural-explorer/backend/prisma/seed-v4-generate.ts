/**
 * v4.0 内容生成器 —— 纯 DeepSeek 生成，保存到 JSON 文件
 * 无需数据库，离线生成所有 34 个地区的内容
 *
 * 运行方式: npx tsx prisma/seed-v4-generate.ts
 * 输出: prisma/seed-v4-output.json
 */

import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.DEEPSEEK_API_KEY || '';
const BASE_URL = process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com';

if (!API_KEY) {
  console.error('❌ 缺少 DEEPSEEK_API_KEY，请在 .env 中配置');
  process.exit(1);
}

const ALL_REGIONS = [
  '北京市', '天津市', '河北省', '山西省', '内蒙古自治区',
  '辽宁省', '吉林省', '黑龙江省',
  '上海市', '江苏省', '浙江省', '安徽省', '福建省', '江西省', '山东省',
  '河南省', '湖北省', '湖南省', '广东省', '广西壮族自治区', '海南省',
  '重庆市', '四川省', '贵州省', '云南省', '西藏自治区',
  '陕西省', '甘肃省', '青海省', '宁夏回族自治区', '新疆维吾尔自治区',
  '台湾省', '香港特别行政区', '澳门特别行政区',
];

const SHORT_NAMES: Record<string, string> = {
  '北京市': '京', '天津市': '津', '河北省': '冀', '山西省': '晋', '内蒙古自治区': '蒙',
  '辽宁省': '辽', '吉林省': '吉', '黑龙江省': '黑', '上海市': '沪', '江苏省': '苏',
  '浙江省': '浙', '安徽省': '皖', '福建省': '闽', '江西省': '赣', '山东省': '鲁',
  '河南省': '豫', '湖北省': '鄂', '湖南省': '湘', '广东省': '粤', '广西壮族自治区': '桂',
  '海南省': '琼', '重庆市': '渝', '四川省': '川', '贵州省': '黔', '云南省': '滇',
  '西藏自治区': '藏', '陕西省': '陕', '甘肃省': '甘', '青海省': '青', '宁夏回族自治区': '宁',
  '新疆维吾尔自治区': '新', '台湾省': '台', '香港特别行政区': '港', '澳门特别行政区': '澳',
};

const CAPITALS: Record<string, string> = {
  '北京市': '北京', '天津市': '天津', '河北省': '石家庄', '山西省': '太原',
  '内蒙古自治区': '呼和浩特', '辽宁省': '沈阳', '吉林省': '长春', '黑龙江省': '哈尔滨',
  '上海市': '上海', '江苏省': '南京', '浙江省': '杭州', '安徽省': '合肥',
  '福建省': '福州', '江西省': '南昌', '山东省': '济南', '河南省': '郑州',
  '湖北省': '武汉', '湖南省': '长沙', '广东省': '广州', '广西壮族自治区': '南宁',
  '海南省': '海口', '重庆市': '重庆', '四川省': '成都', '贵州省': '贵阳',
  '云南省': '昆明', '西藏自治区': '拉萨', '陕西省': '西安', '甘肃省': '兰州',
  '青海省': '西宁', '宁夏回族自治区': '银川', '新疆维吾尔自治区': '乌鲁木齐',
  '台湾省': '台北', '香港特别行政区': '香港', '澳门特别行政区': '澳门',
};

const QUESTIONS_CACHE: Record<string, Array<{
  question: string;
  options: string[];
  correctAnswer: number;
  explanation: string;
  type: string;
  difficulty: number;
  tags: string[];
}>> = {};

async function generateContent(name: string): Promise<any> {
  const displayName = name.replace(/市|省|自治区|特别行政区/g, '');

  const prompt = `你是一位中国地理文化专家。请为"${name}"生成文化内容。严格以JSON格式输出，不要加markdown代码块标记。

{
  "description": "120字简介，生动有画面感",
  "geography": "地理介绍200字，包含地形位置",
  "history": "历史介绍200字，包含重要朝代",
  "culture": "文化介绍200字，包含民俗特色",
  "terrain": "地形地貌描述150字",
  "climate": "气候特征100字",
  "rivers": [{"name":"河流名","description":"一句话介绍"}],
  "mountains": [{"name":"山脉名","description":"一句话介绍"}],
  "historyTimeline": [{"year":"年份或朝代","title":"事件标题","description":"一句话描述"}],
  "famousPeople": [{"name":"姓名","dynasty":"朝代或年代","title":"身份头衔","description":"简短介绍"}],
  "intangibleHeritage": [{"name":"非遗名称","level":"国家级或省级","category":"传统技艺/音乐/美术/舞蹈/戏剧/民俗","description":"一句话介绍"}],
  "festivals": "特色节日描述100字",
  "cuisines": [{"name":"美食名","category":"主食/小吃/菜肴/饮品","description":"一句话描述"}],
  "dialects": "方言特色60字",
  "ancientName": "古称",
  "foundingYear": "建城或建制年份",
  "regionGroup": "华东/华北/华南/西南/西北/东北/港澳台之一",
  "area": "面积",
  "population": "人口约数"
}

要求：历史时间轴至少10条，名人至少5位，非遗至少3项，美食至少4道。内容真实准确。`;

  console.log(`  📡 调用 DeepSeek API...`);

  const resp = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages: [{ role: 'system', content: '你是一位中国地理文化专家，只输出JSON，不输出任何markdown或解释。' }, { role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 8192,
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`HTTP ${resp.status}: ${errText.slice(0, 300)}`);
  }

  const json: any = await resp.json();
  if (!json.choices?.[0]?.message?.content) {
    throw new Error(`API 返回数据异常: ${JSON.stringify(json).slice(0, 300)}`);
  }

  let content = json.choices[0].message.content;
  // 移除可能的 markdown 代码块标记
  content = content.replace(/^```json\s*/i, '').replace(/```\s*$/, '').trim();

  return JSON.parse(content);
}

async function generateQuestionsForRegion(name: string): Promise<Array<{
  question: string;
  options: string[];
  correctAnswer: number;
  explanation: string;
  type: string;
  difficulty: number;
  tags: string[];
}>> {
  const displayName = name.replace(/市|省|自治区|特别行政区/g, '');
  const cap = CAPITALS[name] || '';
  const sn = SHORT_NAMES[name] || '';

  const prompt = `请为"${name}（${displayName}）"生成10道文化知识题。严格以JSON数组格式输出，不要加markdown。每道题格式：
{
  "question": "题目",
  "options": ["A选项","B选项","C选项","D选项"],
  "correctAnswer": 正确选项索引(0-3),
  "explanation": "一句话解释",
  "type": "single",
  "difficulty": 1-3数字,
  "tags": ["标签1","标签2"]
}

要求：
- 涵盖地理、历史、文化、名人、美食、非遗等方面
- 至少2道判断题(type为"truefalse", options为["对","错"])
- 至少1道多选题(type为"multiple")
- 难度从1到3分布
- 全部10道题`;

  console.log(`  📡 生成题目...`);

  const resp = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages: [{ role: 'system', content: '你是一位中国文化考试命题专家，只输出JSON数组，不输出任何额外内容。' }, { role: 'user', content: prompt }],
      temperature: 0.8,
      max_tokens: 4096,
    }),
  });

  if (!resp.ok) return [];

  const json: any = await resp.json();
  if (!json.choices?.[0]?.message?.content) return [];

  let content = json.choices[0].message.content;
  content = content.replace(/^```json\s*/i, '').replace(/```\s*$/, '').trim();

  try {
    return JSON.parse(content);
  } catch {
    return [];
  }
}

async function main() {
  console.log('🚀 v4.0 内容生成器 —— 34 个地区\n');
  console.log(`API Key: ${API_KEY.slice(0, 8)}...`);
  console.log(`Base URL: ${BASE_URL}\n`);

  const results: Record<string, any> = {};
  const outputPath = path.join(__dirname, 'seed-v4-output.json');

  // 尝试加载已有缓存
  if (fs.existsSync(outputPath)) {
    try {
      const cached = JSON.parse(fs.readFileSync(outputPath, 'utf-8'));
      Object.assign(results, cached);
      console.log(`📂 加载已有缓存: ${Object.keys(cached).length} 个地区\n`);
    } catch {}
  }

  for (let i = 0; i < ALL_REGIONS.length; i++) {
    const name = ALL_REGIONS[i];
    const displayName = name.replace(/市|省|自治区|特别行政区/g, '');

    // 跳过已生成的
    if (results[displayName]) {
      const r = results[displayName];
      console.log(`[${i + 1}/${ALL_REGIONS.length}] ⏭ ${name} (已缓存 | 时间轴${r.historyTimeline?.length || 0} | 名人${r.famousPeople?.length || 0} | 美食${r.cuisines?.length || 0} | 非遗${r.intangibleHeritage?.length || 0} | 题目${(results[displayName + '_questions'] || []).length})`);
      continue;
    }

    console.log(`\n[${i + 1}/${ALL_REGIONS.length}] 🤖 ${name}...`);

    try {
      const content = await generateContent(name);
      const questions = await generateQuestionsForRegion(name);

      const cap = CAPITALS[name] || '';
      const sn = SHORT_NAMES[name] || '';

      results[displayName] = {
        name: displayName,
        fullName: name,
        shortName: sn,
        capital: cap,
        description: content.description || '',
        geography: content.geography || '',
        history: content.history || '',
        culture: content.culture || '',
        terrain: content.terrain || '',
        climate: content.climate || '',
        rivers: content.rivers || [],
        mountains: content.mountains || [],
        historyTimeline: content.historyTimeline || [],
        famousPeople: content.famousPeople || [],
        intangibleHeritage: content.intangibleHeritage || [],
        festivals: content.festivals || '',
        cuisines: content.cuisines || [],
        dialects: content.dialects || '',
        ancientName: content.ancientName || '',
        foundingYear: content.foundingYear || '',
        regionGroup: content.regionGroup || '',
        area: content.area || '',
        population: content.population || '',
      };

      results[displayName + '_questions'] = questions || [];

      // 每生成一个就保存（防止中断丢失）
      fs.writeFileSync(outputPath, JSON.stringify(results, null, 2), 'utf-8');

      console.log(`   ✅ 时间轴${content.historyTimeline?.length || 0} | 名人${content.famousPeople?.length || 0} | 美食${content.cuisines?.length || 0} | 非遗${content.intangibleHeritage?.length || 0} | 题目${questions?.length || 0}`);
    } catch (err: any) {
      console.error(`   ❌ ${name} 失败: ${err.message}`);
      // 继续处理下一个
    }

    // API 限流
    if (i < ALL_REGIONS.length - 1) {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  fs.writeFileSync(outputPath, JSON.stringify(results, null, 2), 'utf-8');

  const totalRegions = Object.keys(results).filter(k => !k.endsWith('_questions')).length;
  const totalQuestions = Object.keys(results)
    .filter(k => k.endsWith('_questions'))
    .reduce((sum, k) => sum + (results[k]?.length || 0), 0);

  console.log(`\n🎉 全部完成!`);
  console.log(`   地区内容: ${totalRegions}/34`);
  console.log(`   题目总数: ${totalQuestions}`);
  console.log(`   输出文件: ${outputPath}\n`);
}

main();
