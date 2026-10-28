import { redisPipeline, utcDate, type UpstashEnv } from './ratelimit';

/**
 * 무료 티어 일별 집계(tobe L-02). 개선을 했으면 전후 숫자로 효과를 봐야 한다.
 *
 * 날짜(UTC)마다 해시 하나 `st:YYYY-MM-DD`에 숫자만 쌓는다 — 기기 ID·IP는 넣지 않는다.
 *   dau          그날 처음 차감된 기기 수. 그날 첫 요청이 업스트림 실패로 환불되면
 *                다음 요청에서 한 번 더 셀 수 있다(드물어서 감수).
 *   req:<kind>   통과한 요청 수(업스트림 실패로 환불된 것 포함 — up:*로 뺀다).
 *                kind는 앱이 보내는 `x-kind`(chat·suggest·level·pron).
 *                헤더가 없는 앱(5.0.0 이하)은 스트리밍이면 chat, 아니면 aux(제안·레벨·발음)
 *                — 그 버전은 대화만 스트리밍으로 보낸다(conversation_pipeline.dart).
 *   ver:<버전>   그날 처음 차감된 기기의 앱 버전(User-Agent).
 *   wall         하루 한도를 넘겨 처음 거절된 기기 수 — 한도보다 더 쓰고 싶었던 사람.
 *   up:<코드>    업스트림 실패로 환불한 요청 수(429 = 제공자 한도, 0 = 네트워크 예외).
 *
 * 집계가 실패해도 요청은 막지 않는다 — 로그만 남긴다.
 * 명령 수(Upstash Free 월 50만): 통과 요청마다 1, 기기의 그날 첫 요청에 3, 거절·실패에 2.
 */

const STATS_TTL_SEC = 60 * 60 * 24 * 120;
const KINDS = new Set(['chat', 'suggest', 'level', 'pron']);

export function statsKey(date: string = utcDate()): string {
  return `st:${date}`;
}

/** 모르는 헤더 값은 버린다 — 아무 값이나 필드로 만들면 해시가 끝없이 커진다. */
export function requestKind(req: Request, stream: boolean): string {
  const v = req.headers.get('x-kind')?.trim().toLowerCase() ?? '';
  if (KINDS.has(v)) return v;
  return stream ? 'chat' : 'aux';
}

/** User-Agent `KoreanFriend/5.0.1`의 버전. 형식이 다르면 unknown. */
export function appVersion(req: Request): string {
  const ua = req.headers.get('user-agent') ?? '';
  const m = /KoreanFriend\/(\d{1,3}(?:\.\d{1,3}){0,3})(?![\d.])/.exec(ua);
  return m ? m[1] : 'unknown';
}

async function bump(
  env: UpstashEnv,
  fields: string[],
  withExpire: boolean,
  label: string
): Promise<void> {
  const key = statsKey();
  const commands: (string | number)[][] = fields.map((f) => ['HINCRBY', key, f, 1]);
  // 요청마다 EXPIRE를 붙이면 명령이 두 배다. 그날 첫 기기 요청이 반드시 오므로 그때 건다.
  if (withExpire) commands.push(['EXPIRE', key, STATS_TTL_SEC]);
  try {
    await redisPipeline(env, commands);
  } catch (e: any) {
    console.log(`[stats] ${label} failed:`, e?.message);
  }
}

/** 차감된 요청 1건. firstToday면 기기 수와 앱 버전도 센다. 실패해도 resolve한다. */
export function recordAdmitted(
  env: UpstashEnv,
  req: Request,
  stream: boolean,
  firstToday: boolean
): Promise<void> {
  const fields = [`req:${requestKind(req, stream)}`];
  if (firstToday) fields.push('dau', `ver:${appVersion(req)}`);
  return bump(env, fields, firstToday, 'admitted');
}

export function recordWall(env: UpstashEnv): Promise<void> {
  return bump(env, ['wall'], true, 'wall');
}

export function recordUpstreamFailure(env: UpstashEnv, status: number | null): Promise<void> {
  return bump(env, [`up:${status ?? 0}`], true, 'upstream');
}

export interface DailyStats {
  date: string;
  dau: number;
  requests: number;
  byKind: Record<string, number>;
  versions: Record<string, number>;
  wall: number;
  upstreamFailures: Record<string, number>;
}

/** 오늘(UTC)부터 거꾸로 days일. 기록이 없는 날은 0으로 채운다. */
export async function readDailyStats(env: UpstashEnv, days: number): Promise<DailyStats[]> {
  const now = Date.now();
  const dates = Array.from({ length: days }, (_, i) =>
    new Date(now - i * 86_400_000).toISOString().slice(0, 10)
  );
  const rows = await redisPipeline(env, dates.map((d) => ['HGETALL', statsKey(d)]));
  return dates.map((date, i) => toDailyStats(date, rows[i]));
}

// Upstash REST의 HGETALL은 [필드, 값, 필드, 값, ...] 평면 배열이다.
function toDailyStats(date: string, raw: unknown): DailyStats {
  const stats: DailyStats = {
    date,
    dau: 0,
    requests: 0,
    byKind: {},
    versions: {},
    wall: 0,
    upstreamFailures: {},
  };
  const flat = Array.isArray(raw) ? raw : [];
  for (let i = 0; i + 1 < flat.length; i += 2) {
    const field = String(flat[i]);
    const n = parseInt(String(flat[i + 1]), 10) || 0;
    if (field === 'dau') stats.dau = n;
    else if (field === 'wall') stats.wall = n;
    else if (field.startsWith('req:')) {
      stats.byKind[field.slice(4)] = n;
      stats.requests += n;
    } else if (field.startsWith('ver:')) stats.versions[field.slice(4)] = n;
    else if (field.startsWith('up:')) stats.upstreamFailures[field.slice(3)] = n;
  }
  return stats;
}
