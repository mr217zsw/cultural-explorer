import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly configured: boolean;

  constructor(private readonly config: ConfigService) {
    const accessKey = this.config.get<string>('CST_ACCESS_KEY', '');
    const secretKey = this.config.get<string>('CST_SECRET_KEY', '');
    const endpoint = this.config.get<string>('CST_ENDPOINT', '');
    const region = this.config.get<string>('CST_REGION', 'cn-north-1');
    this.bucket = this.config.get<string>('CST_BUCKET', '');
    this.configured = !!(accessKey && secretKey && endpoint && this.bucket);

    this.client = new S3Client({
      region,
      endpoint,
      credentials: { accessKeyId: accessKey, secretAccessKey: secretKey },
      forcePathStyle: true,
    });
  }

  /** 上传文件 */
  async upload(
    file: Buffer,
    originalName: string,
    folder: string,
    opts?: { contentType?: string; isPublic?: boolean },
  ): Promise<string> {
    const ext = path.extname(originalName) || '.bin';
    const key = `${folder}/${uuidv4()}${ext}`;
    const contentType = opts?.contentType ?? this.guessContentType(ext);

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file,
        ContentType: contentType,
        ...(opts?.isPublic !== false ? { ACL: 'public-read' as const } : {}),
      }),
    );

    const endpoint = this.config.get<string>('CST_ENDPOINT', '').replace(/\/$/, '');
    return `${endpoint}/${this.bucket}/${key}`;
  }

  /** 上传图片 */
  async uploadImage(file: Buffer, originalName: string, folder = 'images'): Promise<string> {
    return this.upload(file, originalName, folder, {
      contentType: `image/${path.extname(originalName).replace('.', '') || 'jpeg'}`,
    });
  }

  /** 上传音频 */
  async uploadAudio(file: Buffer, originalName: string, folder = 'audio'): Promise<string> {
    return this.upload(file, originalName, folder, { contentType: 'audio/mpeg' });
  }

  /** 删除文件 */
  async deleteFile(url: string): Promise<void> {
    const key = this.extractKey(url);
    if (!key) return;
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
  }

  /** 从URL提取对象Key */
  private extractKey(url: string): string | null {
    try {
      const u = new URL(url);
      const prefix = `/${this.bucket}/`;
      if (u.pathname.startsWith(prefix)) {
        return u.pathname.slice(prefix.length);
      }
      return null;
    } catch {
      return null;
    }
  }

  /** 猜测文件类型 */
  private guessContentType(ext: string): string {
    const map: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.ogg': 'audio/ogg',
      '.mp4': 'video/mp4',
      '.pdf': 'application/pdf',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }
}
