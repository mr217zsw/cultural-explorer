import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class RedisService {
  private readonly logger = new Logger(RedisService.name);
  private readonly baseUrl: string;
  private readonly token: string;

  constructor(private readonly config: ConfigService) {
    this.baseUrl = this.config.get<string>('UPSTASH_REDIS_REST_URL', '');
    this.token = this.config.get<string>('UPSTASH_REDIS_REST_TOKEN', '');
  }

  private get isConfigured(): boolean {
    return !!(this.baseUrl && this.token);
  }

  private async request(path: string, method: string, body?: unknown) {
    if (!this.isConfigured) return null;
    try {
      const res = await fetch(`${this.baseUrl}${path}`, {
        method,
        headers: { Authorization: `Bearer ${this.token}`, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });
      const data = await res.json();
      if (!res.ok && data.error) {
        this.logger.warn(`Redis ${method} ${path}: ${data.error}`);
        return null;
      }
      return data;
    } catch (e) {
      this.logger.warn(`Redis request failed: ${e}`);
      return null;
    }
  }

  /** GET key - returns parsed value */
  async get<T = string>(key: string): Promise<T | null> {
    const data = await this.request(`/get/${encodeURIComponent(key)}`, 'GET');
    if (!data || data.result === null || data.result === undefined) return null;
    try { return JSON.parse(data.result) as T; } catch { return data.result as T; }
  }

  /** SET key with optional expiration in seconds */
  async set(key: string, value: unknown, ex?: number): Promise<boolean> {
    const query = ex ? `?EX=${ex}` : '';
    const body = typeof value === 'string' ? value : JSON.stringify(value);
    const data = await this.request(`/set/${encodeURIComponent(key)}${query}`, 'POST', body);
    return data?.result === 'OK';
  }

  /** DELETE key */
  async del(key: string): Promise<boolean> {
    const data = await this.request(`/del/${encodeURIComponent(key)}`, 'GET');
    return data?.result === 1;
  }

  /** EXISTS key */
  async exists(key: string): Promise<boolean> {
    const data = await this.request(`/exists/${encodeURIComponent(key)}`, 'GET');
    return data?.result === 1;
  }

  /** EXPIRE key seconds */
  async expire(key: string, seconds: number): Promise<boolean> {
    const data = await this.request(`/expire/${encodeURIComponent(key)}/${seconds}`, 'GET');
    return data?.result === 1;
  }

  /** TTL key */
  async ttl(key: string): Promise<number> {
    const data = await this.request(`/ttl/${encodeURIComponent(key)}`, 'GET');
    return data?.result ?? -2;
  }

  /** Get or set cache (cache-aside pattern) */
  async getOrSet<T>(key: string, factory: () => Promise<T>, ttlSeconds = 3600): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;

    const value = await factory();
    await this.set(key, value, ttlSeconds);
    return value;
  }
}
