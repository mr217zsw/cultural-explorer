/**
 * v4.0 媒体生成器 —— 配图 + 配音 批量生成
 * 运行: npx tsx prisma/seed-v4-media.ts
 */
import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import * as dns from 'dns';

// 解析 Supabase IPv4（IPv6 不通）
async function resolveIPv4(host: string): Promise<string> {
  return new Promise((resolve) => {
    dns.resolve4(host, (err, addrs) => {
      resolve(addrs?.[0] || host);
    });
  });
}

async function getPrisma(): Promise<PrismaClient> {
  const host = 'aws-1-us-west-2.pooler.supabase.com';
  const ip = await resolveIPv4(host);
  const url = `postgresql://postgres.oppyytiomwyxojhopjco:oIgv5ndQFM1GkiLa@${ip}:6543/postgres?pgbouncer=true&connection_limit=1&sslmode=no-verify`;
  return new PrismaClient({ datasources: { db: { url } } });
}

// dotenvx 加密兼容：从 .env 文件直接读取
function readEnvKey(name: string): string {
  const val = process.env[name];
  if (val) return val;
  try {
    const envRaw = fs.readFileSync(path.join(__dirname, '..', '.env'), 'utf-8');
    const match = envRaw.match(new RegExp(`${name}=(.+)`));
    return match ? match[1].trim() : '';
  } catch { return ''; }
}

const DASHSCOPE_KEY = readEnvKey('DASHSCOPE_API_KEY');
const IMAGE_BASE = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis';
const TASK_BASE = 'https://dashscope.aliyuncs.com/api/v1/tasks';
// Edge TTS (微软免费 TTS)
const EDGE_TTS_URL = 'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';

if (!DASHSCOPE_KEY) { console.error('❌ 缺少 DASHSCOPE_API_KEY'); process.exit(1); }

async function logStep(msg: string) { console.log(`\n${msg}`); }

// ─── 文生图 ───
async function generateImage(prompt: string): Promise<string | null> {
  // 提交任务
  const submit = await fetch(IMAGE_BASE, {
    method: 'POST',
    headers: { Authorization: `Bearer ${DASHSCOPE_KEY}`, 'Content-Type': 'application/json', 'X-DashScope-Async': 'enable' },
    body: JSON.stringify({
      model: 'wanx-v1',
      input: { prompt, negative_prompt: '低质量, 模糊, 变形, 文字, 水印, 签名' },
      parameters: { n: 1, size: '1024*1024' },
    }),
  });
  const submitJson = await submit.json() as any;
  if (!submitJson.output?.task_id) {
    console.log(`   ❌ 提交失败: ${JSON.stringify(submitJson).slice(0, 200)}`);
    return null;
  }
  const taskId = submitJson.output.task_id;

  // 轮询结果
  for (let i = 0; i < 20; i++) {
    await sleep(6000);
    const poll = await fetch(`${TASK_BASE}/${taskId}`, {
      headers: { Authorization: `Bearer ${DASHSCOPE_KEY}` },
    });
    const pollJson = await poll.json() as any;
    const status = pollJson.output?.task_status || pollJson.status;
    if (status === 'SUCCEEDED') {
      const results = pollJson.output?.results;
      return results?.[0]?.url || null;
    }
    if (status === 'FAILED') {
      console.log(`   ❌ 生成失败: ${pollJson.output?.message || pollJson.message || '未知'}`);
      return null;
    }
    process.stdout.write('.');
  }
  console.log('   ⏱ 超时');
  return null;
}

// ─── TTS (阿里云百炼 sambert WebSocket) ───
const WebSocket = require('ws');

async function generateAudio(text: string): Promise<Buffer | null> {
  return new Promise((resolve) => {
    try {
      const ws = new WebSocket('wss://dashscope.aliyuncs.com/api-ws/v1/inference', {
        headers: { Authorization: `Bearer ${DASHSCOPE_KEY}` },
      });
      const chunks: Buffer[] = [];
      const t = setTimeout(() => { ws.close(); resolve(null); }, 30000);

      ws.on('open', () => {
        ws.send(JSON.stringify({
          header: { action: 'run-task', task_id: `t-${Date.now()}`, streaming: 'out' },
          payload: {
            model: 'sambert-zhichu-v1',
            task_group: 'audio',
            task: 'tts',
            function: 'SpeechSynthesizer',
            input: { text: text.slice(0, 500) },
            parameters: { text_type: 'PlainText', format: 'mp3', sample_rate: 16000, volume: 50, rate: 0, pitch: 0 },
          },
        }));
      });

      ws.on('message', (data: Buffer, isBinary: boolean) => {
        if (isBinary) { chunks.push(data); return; }
        const m = JSON.parse(data.toString());
        const ev = m.header?.event;
        if (ev === 'task-failed') { clearTimeout(t); ws.close(); resolve(null); }
        if (ev === 'task-finished') {
          clearTimeout(t); ws.close();
          const full = Buffer.concat(chunks);
          resolve(full.length > 0 ? full : null);
        }
      });
      ws.on('error', () => { clearTimeout(t); resolve(null); });
    } catch (err) { resolve(null); }
  });
}

function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

function buildImagePrompt(name: string, landmark?: string): string {
  const l = landmark ? `, 标志性建筑${landmark}` : '';
  return `中国${name}${l}, 中国风插画风格, 精致细节, 浓郁文化气息, 鲜艳色彩, 高质量, 竖版9:16, 适合旅行App封面, 艺术性, 温暖色调`;
}

function buildAudioText(name: string, desc: string, geo: string, hist: string): string {
  return `欢迎来到${name}。${desc || ''}。${geo || ''}。${hist || ''}。探索${name}的文化之美。`;
}

// ─── 主流程 ───
async function main() {
  const prisma = await getPrisma();
  const args = process.argv.slice(2);
  const onlyImages = args.includes('--images-only');
  const onlyAudio = args.includes('--audio-only');
  const target = args.find(a => a.startsWith('--name='))?.split('=')[1];

  const regions = target
    ? await prisma.region.findMany({ where: { name: { contains: target } } })
    : await prisma.region.findMany({ orderBy: { sortOrder: 'asc' }, include: { landmarks: { take: 1, orderBy: { sortOrder: 'asc' } } } });

  console.log(`🎨 媒体生成器 | 通义万相\n   地区: ${regions.length} | 配图: ${onlyAudio ? '跳过' : '✅'} | 配音: ${onlyImages ? '跳过' : '✅'}\n`);

  let imgCount = 0, audioCount = 0;
  const PUBLIC_DIR = path.resolve(__dirname, '..', 'public');
  const COVERS_DIR = path.join(PUBLIC_DIR, 'covers');
  const AUDIO_DIR = path.join(PUBLIC_DIR, 'audio');
  if (!fs.existsSync(COVERS_DIR)) fs.mkdirSync(COVERS_DIR, { recursive: true });
  if (!fs.existsSync(AUDIO_DIR)) fs.mkdirSync(AUDIO_DIR, { recursive: true });

  for (let i = 0; i < regions.length; i++) {
    const r = regions[i];
    const landmark = (r as any).landmarks?.[0]?.name || '';
    console.log(`[${i + 1}/${regions.length}] ${r.name}...`);

    // ── 配图 ──
    if (!onlyAudio) {
      const localImgPath = path.join(COVERS_DIR, `${r.name}.jpg`);
      const localImgExists = fs.existsSync(localImgPath);
      const existingImg = r.heroImage || r.coverImage;
      const isLocal = existingImg?.startsWith('/static/');
      if (localImgExists || (isLocal && !target)) {
        console.log(`   🖼️ 本地已有，跳过`);
      } else {
        let imgUrl: string | null = null;
        if (existingImg && existingImg.startsWith('http') && !target) {
          // 已存在的远程图片：尝试下载到本地
          console.log(`   🖼️ 下载远程图片到本地..`);
          try {
            const resp = await fetch(existingImg);
            if (resp.ok) {
              const buf = Buffer.from(await resp.arrayBuffer());
              fs.writeFileSync(localImgPath, buf);
              const localUrl = `/static/covers/${r.name}.jpg`;
              await prisma.region.update({ where: { id: r.id }, data: { heroImage: localUrl } });
              imgCount++;
              console.log(` ✅ ${localUrl} (${buf.length} bytes)`);
              continue;
            }
          } catch {}
          // 下载失败 → 重新生成
          console.log(`   🖼️ 远程 URL 失效，重新生成..`);
        } else if (!target) {
          console.log(`   🖼️ 重新生成..`);
        } else {
          console.log(`   🖼️ 生成中..`);
        }
        const prompt = buildImagePrompt(r.name, landmark);
        process.stdout.write(`   `);
        imgUrl = await generateImage(prompt);
        if (imgUrl) {
          try {
            const resp = await fetch(imgUrl);
            if (resp.ok) {
              const buf = Buffer.from(await resp.arrayBuffer());
              fs.writeFileSync(localImgPath, buf);
              const localUrl = `/static/covers/${r.name}.jpg`;
              await prisma.region.update({ where: { id: r.id }, data: { heroImage: localUrl } });
              imgCount++;
              console.log(` ✅ ${localUrl} (${buf.length} bytes)`);
            }
          } catch (err: any) {
            console.log(`   ❌ 下载失败: ${err.message}`);
          }
        }
      }
    }

    // ── 配音 ──
    if (!onlyImages) {
      const localAudioPath = path.join(AUDIO_DIR, `${r.name}.mp3`);
      const localAudioExists = fs.existsSync(localAudioPath);
      const existingAudio = r.audioShort || r.audioGuide;
      const isLocalAudio = existingAudio?.startsWith('/static/');
      if (localAudioExists || (isLocalAudio && !target)) {
        console.log(`   🎧 本地已有，跳过`);
      } else {
        console.log(`   🎧 生成配音..`);
        const text = buildAudioText(r.name, r.description, r.geography || '', r.history || '');
        const audio = await generateAudio(text);
        if (audio) {
          fs.writeFileSync(localAudioPath, audio);
          const localUrl = `/static/audio/${r.name}.mp3`;
          await prisma.region.update({ where: { id: r.id }, data: { audioGuide: localUrl } });
          audioCount++;
          console.log(` ✅ ${localUrl} (${audio.length} bytes)`);
        } else {
          console.log(`   ❌ TTS 失败`);
        }
      }
    }

    await sleep(800);
  }

  console.log(`\n🎉 完成! 配图${imgCount} | 配音${audioCount}`);
  await prisma.$disconnect();
}

main();
