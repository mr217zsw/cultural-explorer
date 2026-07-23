/**
 * v4.0 媒体上传器 —— 本地配图+配音上传到数据胶囊 S3
 * 运行: npx tsx prisma/seed-v4-upload.ts
 */
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaClient } from '@prisma/client';
import * as dns from 'dns';

// 读取 .env（dotenvx 兼容）
function readEnvKey(name: string): string {
  const val = process.env[name];
  if (val) return val;
  try {
    const envRaw = fs.readFileSync(path.join(__dirname, '..', '.env'), 'utf-8');
    const match = envRaw.match(new RegExp(`${name}=(.+)`));
    return match ? match[1].trim() : '';
  } catch { return ''; }
}

const CST_ACCESS_KEY = readEnvKey('CST_ACCESS_KEY');
const CST_SECRET_KEY = readEnvKey('CST_SECRET_KEY');
const CST_ENDPOINT = readEnvKey('CST_ENDPOINT');
const CST_BUCKET = readEnvKey('CST_BUCKET');

if (!CST_ACCESS_KEY) { console.error('❌ 缺少 CST_ACCESS_KEY'); process.exit(1); }

const s3 = new S3Client({
  region: 'us-east-1',
  endpoint: CST_ENDPOINT,
  credentials: { accessKeyId: CST_ACCESS_KEY, secretAccessKey: CST_SECRET_KEY },
  forcePathStyle: true,
  customUserAgent: 'Rclone/v1.65.0',
});

async function uploadFile(key: string, filePath: string, contentType: string): Promise<string | null> {
  const buf = fs.readFileSync(filePath);
  try {
    await s3.send(new PutObjectCommand({
      Bucket: CST_BUCKET,
      Key: key,
      Body: buf,
      ContentType: contentType,
    }));
    const url = `https://s3.cstcloud.cn/${CST_BUCKET}/${key}`;
    return url;
  } catch (err: any) {
    console.log(`   ❌ 上传失败: ${err.message}`);
    return null;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const onlyImages = args.includes('--images-only');
  const onlyAudio = args.includes('--audio-only');
  const targetName = args.find(a => a.startsWith('--name='))?.split('=')[1];

  // DNS 修复
  dns.setDefaultResultOrder('ipv4first');
  const host = 'aws-1-us-west-2.pooler.supabase.com';
  const ip = await new Promise<string>(resolve => dns.resolve4(host, (_, a) => resolve(a?.[0] || host)));
  const dbUrl = `postgresql://postgres.oppyytiomwyxojhopjco:oIgv5ndQFM1GkiLa@${ip}:6543/postgres?pgbouncer=true&connection_limit=1&sslmode=no-verify`;
  const prisma = new PrismaClient({ datasources: { db: { url: dbUrl } } });

  const PUBLIC_DIR = path.resolve(__dirname, '..', 'public');
  const COVERS_DIR = path.join(PUBLIC_DIR, 'covers');
  const AUDIO_DIR = path.join(PUBLIC_DIR, 'audio');

  let imgCount = 0, audioCount = 0;

  // 获取需要处理的地区
  const regions = targetName
    ? await prisma.region.findMany({ where: { name: { contains: targetName } } })
    : await prisma.region.findMany({ orderBy: { sortOrder: 'asc' } });

  console.log(`📦 数据胶囊上传 | ${CST_ENDPOINT}/${CST_BUCKET}`);
  console.log(`   地区: ${regions.length} | 配图: ${onlyAudio ? '跳过' : '✅'} | 配音: ${onlyImages ? '跳过' : '✅'}\n`);

  for (let i = 0; i < regions.length; i++) {
    const r = regions[i];
    console.log(`[${i + 1}/${regions.length}] ${r.name}...`);

    // ── 配图上传 ──
    if (!onlyAudio) {
      const imgPath = path.join(COVERS_DIR, `${r.name}.jpg`);
      if (fs.existsSync(imgPath)) {
        const key = `covers/${r.name}.jpg`;
        const url = await uploadFile(key, imgPath, 'image/jpeg');
        if (url) {
          await prisma.region.update({ where: { id: r.id }, data: { heroImage: url } });
          imgCount++;
          console.log(`   🖼️ ✅ ${url.slice(0, 80)}...`);
        }
      } else {
        console.log(`   🖼️ 本地文件不存在`);
      }
    }

    // ── 配音上传 ──
    if (!onlyImages) {
      const audioPath = path.join(AUDIO_DIR, `${r.name}.mp3`);
      if (fs.existsSync(audioPath)) {
        const key = `audio/${r.name}.mp3`;
        const url = await uploadFile(key, audioPath, 'audio/mpeg');
        if (url) {
          await prisma.region.update({ where: { id: r.id }, data: { audioGuide: url } });
          audioCount++;
          console.log(`   🎧 ✅ ${url.slice(0, 80)}...`);
        }
      } else {
        console.log(`   🎧 本地文件不存在`);
      }
    }
  }

  console.log(`\n🎉 上传完成! 配图${imgCount} | 配音${audioCount}`);
  await prisma.$disconnect();
}

main();
