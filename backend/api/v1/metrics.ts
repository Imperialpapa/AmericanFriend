import { json, safeEqual, secretEnv } from '../../lib/common';
import { upstashEnv } from '../../lib/ratelimit';
import { readDailyStats, type DailyStats } from '../../lib/stats';

export const config = { runtime: 'edge' };

/**
 * 무료 티어 일별 집계 조회(tobe L-02). 운영자 전용 — `x-monitor-token: $MONITOR_TOKEN`.
 *
 *   GET /api/v1/metrics?days=14   오늘(UTC)부터 거꾸로 N일(1~120)
 *
 * 무료 티어 사용자만 보인다. 본인 API 키 사용자는 앱 서버를 거치지 않는다.
 * 날짜별 합계뿐이라 개인을 알아볼 수 없다(lib/stats.ts).
 */
export default async function handler(req: Request): Promise<Response> {
  if (req.method !== 'GET') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const noStore = { 'Cache-Control': 'no-store' };
  const token = secretEnv('MONITOR_TOKEN');
  const given = req.headers.get('x-monitor-token') ?? '';
  if (token === undefined || !safeEqual(given, token)) {
    return json({ error: { code: 'unauthorized' } }, 401, noStore);
  }

  const requested = parseInt(new URL(req.url).searchParams.get('days') ?? '14', 10);
  const days = Number.isFinite(requested) ? Math.min(120, Math.max(1, requested)) : 14;

  try {
    const rows = await readDailyStats(upstashEnv(), days);
    return json({ ok: true, days: rows.map(withRatios) }, 200, noStore);
  } catch (e: any) {
    console.log('[metrics] error:', e?.message);
    return json({ error: { code: 'internal' } }, 500, noStore);
  }
}

/** 기기당 요청·대화 수와 한도 도달률(%). 기기 수가 0이면 null. */
function withRatios(s: DailyStats) {
  const perDevice = (n: number) => (s.dau > 0 ? Math.round((n / s.dau) * 10) / 10 : null);
  return {
    ...s,
    requestsPerDevice: perDevice(s.requests),
    chatPerDevice: perDevice(s.byKind.chat ?? 0),
    wallRatePct: s.dau > 0 ? Math.round((s.wall / s.dau) * 1000) / 10 : null,
  };
}
