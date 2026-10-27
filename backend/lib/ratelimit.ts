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
 * 일일 카운터들을 한 왕복에 올린다. Upstash는 파이프라인·스크립트 안의 명령도
 * 하나씩 과금하므로(Free 월 50만) 요청마다는 INCR만 보내고, 그날 처음 생긴 키
 * (결과 1)에만 EXPIRE를 붙인다. 키에 날짜가 있어 EXPIRE가 실패해도 한도 계산은
 * 맞다 — 옛 키가 남을 뿐이라 요청을 막지 않는다.
 */
export async function incrementDaily(env: UpstashEnv, keys: string[]): Promise<number[]> {
  const counts = (await redisPipeline(env, keys.map((k) => ['INCR', k]))).map(Number);
  const fresh = keys.filter((_, i) => counts[i] === 1);
  if (fresh.length > 0) {
    try {
      await redisPipeline(env, fresh.map((k) => ['EXPIRE', k, DAY_TTL_SEC]));
    } catch (e: any) {
      console.log('[rate-limit] expire failed:', e?.message);
    }
  }
  return counts;
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

/** 통과한 요청이 올린 카운터 키. */
export interface ChargedKeys {
  global: string;
  ip: string;
  device: string;
}

export type AdmitResult =
  | { kind: 'ok'; device: RateLimitResult; charged: ChargedKeys }
  | { kind: 'ip_limited' }
  | { kind: 'global_limited' }
  | { kind: 'device_limited'; device: RateLimitResult };

// 오늘 한도에 걸린 카운터 키. 거절 요청은 개수 제한이 없어, 매번 Upstash를
// 부르면(건당 5명령) 한 명이 월 명령 한도를 태우고 리미터가 fail-closed로 무료 티어
// 전체를 막는다. 인스턴스별 best-effort 캐시라 첫 거절만 명령을 쓴다.
let limitedDay = '';
const limitedKeys = new Set<string>();
const LIMITED_KEYS_MAX = 10_000;

function isLimited(key: string): boolean {
  const today = utcDate();
  if (limitedDay !== today) {
    limitedDay = today;
    limitedKeys.clear();
  }
  return limitedKeys.has(key);
}

function markLimited(key: string): void {
  if (limitedKeys.size >= LIMITED_KEYS_MAX) limitedKeys.clear();
  limitedKeys.add(key);
}

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

  if (isLimited(iKey)) return { kind: 'ip_limited' };
  if (isLimited(gKey)) return { kind: 'global_limited' };
  if (isLimited(dKey)) {
    return { kind: 'device_limited', device: deviceResult(limits.device + 1, limits.device) };
  }

  const [globalUsed, ipUsed, deviceUsed] = await incrementDaily(env, [gKey, iKey, dKey]);

  if (ipUsed > limits.ip) {
    await refund(env, [gKey, dKey]);
    markLimited(iKey);
    return { kind: 'ip_limited' };
  }
  if (globalUsed > limits.global) {
    await refund(env, [iKey, dKey]);
    markLimited(gKey);
    return { kind: 'global_limited' };
  }
  const device = deviceResult(deviceUsed, limits.device);
  if (!device.allowed) {
    await refund(env, [gKey, iKey]);
    markLimited(dKey);
    return { kind: 'device_limited', device };
  }
  return { kind: 'ok', device, charged: { global: gKey, ip: iKey, device: dKey } };
}

/**
 * 업스트림이 첫 바이트 전에 실패한 요청의 차감을 되돌린다.
 * upstreamStatus가 null이면 응답 없이 예외(네트워크 등)로 끝난 경우.
 *
 * - 기기: 항상 — 우리 쪽 실패로 사용자 하루 한도를 깎지 않는다.
 * - 전역: 제공자 장애(5xx·예외)일 때만 — 장애가 풀린 뒤 예산이 남아 있게.
 * - IP: 되돌리지 않는다. 413처럼 매번 실패하는 요청까지 전액 환불하면 IP 한도에
 *   걸리지 않아, 한 IP가 Upstash·업스트림 호출을 무제한으로 쓴다.
 */
export async function refundFailedCall(
  env: UpstashEnv,
  charged: ChargedKeys,
  upstreamStatus: number | null
): Promise<void> {
  const providerFault = upstreamStatus === null || upstreamStatus >= 500;
  await refund(env, providerFault ? [charged.device, charged.global] : [charged.device]);
}

/** 오늘 전역 카운터 값(명령 1개). 카운터를 올리지 않는 모니터용. */
export async function peekGlobal(env: UpstashEnv): Promise<number> {
  const raw = await redisCommand(env, ['GET', globalKey()]);
  return raw ? parseInt(String(raw), 10) || 0 : 0;
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
