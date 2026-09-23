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

export interface UpstashEnv {
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

/** 날짜가 붙은 일일 카운터 키. incrementDaily()와 함께 쓴다. */
export function dailyKey(prefix: string, id: string): string {
  return `${prefix}:${id}:${utcDate()}`;
}

function todayKey(deviceId: string): string {
  return dailyKey('rl', deviceId);
}

function globalKey(): string {
  return `rlg:${utcDate()}`;
}

function ipKey(ipId: string): string {
  return dailyKey('rli', ipId);
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

/**
 * 여러 명령을 한 왕복으로 보낸다. Edge가 Upstash와 먼 리전에서 돌 수 있어
 * 왕복 수가 곧 첫 응답 지연이다(tobe S-10).
 */
export async function redisPipeline(
  env: UpstashEnv,
  commands: (string | number)[][]
): Promise<unknown[]> {
  const res = await fetch(`${env.url.replace(/\/+$/, '')}/pipeline`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(commands),
  });
  if (!res.ok) {
    throw new Error(`upstash ${res.status}: ${await res.text()}`);
  }
  const data = (await res.json()) as Array<{ result?: unknown; error?: string }>;
  if (!Array.isArray(data) || data.length !== commands.length) {
    throw new Error('upstash: malformed pipeline response');
  }
  const failed = data.find((d) => d?.error);
  if (failed) throw new Error(`upstash: ${failed.error}`);
  return data.map((d) => d.result);
}

/**
 * 일일 카운터들을 한 번에 올린다. SET NX EX를 INCR 앞에 둬서 만료 없는 키가
 * 남지 않는다 — 예전엔 INCR 뒤 EXPIRE를 따로 보내 그 사이 실패하면 키가 영구히 남았다.
 */
export async function incrementDaily(env: UpstashEnv, keys: string[]): Promise<number[]> {
  const commands = keys.flatMap((k) => [
    ['SET', k, '0', 'EX', DAY_TTL_SEC, 'NX'],
    ['INCR', k],
  ]);
  const results = await redisPipeline(env, commands);
  return keys.map((_, i) => Number(results[i * 2 + 1]));
}

/** 처리하지 못한 요청의 차감을 되돌린다. 실패해도 응답은 막지 않는다. */
export async function refund(env: UpstashEnv, keys: string[]): Promise<void> {
  if (keys.length === 0) return;
  try {
    await redisPipeline(env, keys.map((k) => ['DECR', k]));
  } catch (e: any) {
    console.log('[rate-limit] refund failed:', e?.message);
  }
}

function deviceResult(used: number, limit: number): RateLimitResult {
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
  | { kind: 'ok'; device: RateLimitResult; charged: string[] }
  | { kind: 'ip_limited' }
  | { kind: 'global_limited' }
  | { kind: 'device_limited'; device: RateLimitResult };

/**
 * 무료 티어 입장 판정. device-id는 클라이언트가 만드는 값이라 기기 한도만으로는
 * id를 바꿔 가며 무제한 호출이 된다(tobe S-01). 전역 상한이 비용의 최종 방어선이다.
 *
 * 세 카운터를 한 왕복에 올린 뒤, 거절 사유가 아닌 카운터는 되돌린다.
 * 거절된 요청이 전역 예산을 태우면 한 IP·한 기기가 모든 사용자를 막을 수 있다.
 * 판정 우선순위는 IP → 전역 → 기기.
 */
export async function admitFreeTier(
  env: UpstashEnv,
  deviceId: string,
  ipId: string,
  limits: FreeTierLimits
): Promise<AdmitResult> {
  const gKey = globalKey();
  const iKey = ipKey(ipId);
  const dKey = todayKey(deviceId);
  const [globalUsed, ipUsed, deviceUsed] = await incrementDaily(env, [gKey, iKey, dKey]);

  if (ipUsed > limits.ip) {
    await refund(env, [gKey, dKey]);
    return { kind: 'ip_limited' };
  }
  if (globalUsed > limits.global) {
    await refund(env, [iKey, dKey]);
    return { kind: 'global_limited' };
  }
  const device = deviceResult(deviceUsed, limits.device);
  if (!device.allowed) {
    await refund(env, [gKey, iKey]);
    return { kind: 'device_limited', device };
  }
  return { kind: 'ok', device, charged: [gKey, iKey, dKey] };
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
