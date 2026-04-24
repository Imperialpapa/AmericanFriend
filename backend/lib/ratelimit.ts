/**
 * Upstash Redis REST API 기반 기기별 일일 rate limit.
 * Edge Runtime에서 fetch만으로 동작.
 *
 * 필요 env:
 *   UPSTASH_REDIS_REST_URL
 *   UPSTASH_REDIS_REST_TOKEN
 */

export interface RateLimitResult {
  allowed: boolean;
  limit: number;
  remaining: number;
  used: number;
  resetAt: string;
}

interface UpstashEnv {
  url: string;
  token: string;
}

function todayKey(deviceId: string): string {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  return `rl:${deviceId}:${yyyy}-${mm}-${dd}`;
}

function nextMidnightUtc(): string {
  const d = new Date();
  d.setUTCHours(24, 0, 0, 0);
  return d.toISOString();
}

async function redisCommand(
  env: UpstashEnv,
  command: (string | number)[]
): Promise<any> {
  const res = await fetch(env.url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(command),
  });
  if (!res.ok) {
    throw new Error(`upstash ${res.status}: ${await res.text()}`);
  }
  const data = await res.json() as any;
  return data.result;
}

export async function checkAndIncrement(
  env: UpstashEnv,
  deviceId: string,
  limit: number
): Promise<RateLimitResult> {
  const key = todayKey(deviceId);
  // 원자적 증가
  const used: number = await redisCommand(env, ['INCR', key]);
  // 첫 증가 시 TTL 설정 (48h — 자정 지나면 자동 정리)
  if (used === 1) {
    await redisCommand(env, ['EXPIRE', key, 60 * 60 * 48]);
  }

  if (used > limit) {
    return {
      allowed: false,
      limit,
      remaining: 0,
      used: used - 1, // rollback 개념상 증가 전 값을 돌려줌
      resetAt: nextMidnightUtc(),
    };
  }

  return {
    allowed: true,
    limit,
    remaining: Math.max(0, limit - used),
    used,
    resetAt: nextMidnightUtc(),
  };
}

export async function peek(
  env: UpstashEnv,
  deviceId: string,
  limit: number
): Promise<RateLimitResult> {
  const key = todayKey(deviceId);
  const raw = await redisCommand(env, ['GET', key]);
  const used = raw ? parseInt(String(raw), 10) || 0 : 0;
  return {
    allowed: used < limit,
    limit,
    remaining: Math.max(0, limit - used),
    used,
    resetAt: nextMidnightUtc(),
  };
}

export function upstashEnv(): UpstashEnv {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) {
    throw new Error('Upstash env not configured (UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN)');
  }
  return { url, token };
}
