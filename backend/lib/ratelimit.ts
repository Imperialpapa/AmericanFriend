/**
 * Upstash Redis REST API 기반 일일 rate limit(기기·IP·전역).
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

// 날짜 키라 자정이 지나면 새 키를 쓰고, 옛 키는 48h 뒤 만료로 정리된다.
const DAY_TTL_SEC = 60 * 60 * 48;

function utcDate(): string {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function todayKey(deviceId: string): string {
  return `rl:${deviceId}:${utcDate()}`;
}

function globalKey(): string {
  return `rlg:${utcDate()}`;
}

function ipKey(ipId: string): string {
  return `rli:${ipId}:${utcDate()}`;
}

function nextMidnightUtc(): string {
  const d = new Date();
  d.setUTCHours(24, 0, 0, 0);
  return d.toISOString();
}

export function secondsUntilReset(): number {
  return Math.max(1, Math.ceil((Date.parse(nextMidnightUtc()) - Date.now()) / 1000));
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

async function incrDaily(env: UpstashEnv, key: string): Promise<number> {
  const used: number = await redisCommand(env, ['INCR', key]);
  if (used === 1) {
    await redisCommand(env, ['EXPIRE', key, DAY_TTL_SEC]);
  }
  return used;
}

export async function checkAndIncrement(
  env: UpstashEnv,
  deviceId: string,
  limit: number
): Promise<RateLimitResult> {
  const used = await incrDaily(env, todayKey(deviceId));

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

export interface FreeTierLimits {
  device: number;
  ip: number;
  global: number;
}

export type AdmitResult =
  | { kind: 'ok'; device: RateLimitResult }
  | { kind: 'ip_limited' }
  | { kind: 'global_limited' }
  | { kind: 'device_limited'; device: RateLimitResult };

/**
 * 무료 티어 입장 판정. device-id는 클라이언트가 만드는 값이라 기기 한도만으로는
 * id를 바꿔 가며 무제한 호출이 된다(tobe S-01). 전역 상한이 비용의 최종 방어선이다.
 *
 * IP를 전역보다 먼저 센다 — 한 IP의 반복 요청이 전역 예산을 태우면 한 명이
 * 모든 사용자를 막을 수 있다.
 */
export async function admitFreeTier(
  env: UpstashEnv,
  deviceId: string,
  ipId: string,
  limits: FreeTierLimits
): Promise<AdmitResult> {
  const ipUsed = await incrDaily(env, ipKey(ipId));
  if (ipUsed > limits.ip) return { kind: 'ip_limited' };
  const globalUsed = await incrDaily(env, globalKey());
  if (globalUsed > limits.global) return { kind: 'global_limited' };
  const device = await checkAndIncrement(env, deviceId, limits.device);
  return device.allowed ? { kind: 'ok', device } : { kind: 'device_limited', device };
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
