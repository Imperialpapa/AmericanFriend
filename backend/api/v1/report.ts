import { corsPreflight, envInt, json, requireDeviceId, sha256Hex } from '../../lib/common';
import {
  dailyKey,
  incrementDaily,
  redisPipeline,
  secondsUntilReset,
  upstashEnv,
} from '../../lib/ratelimit';

export const config = { runtime: 'edge' };

/**
 * AI 응답 신고. Play 'AI 생성 콘텐츠' 정책은 앱을 떠나지 않고 신고할 수 있어야
 * 한다(tobe P-01).
 *
 * 저장: Upstash 리스트 `reports`에 최신순 JSON, 최근 2000건만 유지.
 * 확인: Upstash 콘솔 CLI에서 `LRANGE reports 0 49`.
 *
 * - 채팅 한도와 별개 카운터(`rpt:`)다 — 신고가 대화 쿼터를 깎지 않는다.
 * - 기기 id는 SHA-256 해시로만 남긴다.
 * - 원문이 길면 거절하지 않고 자른다. 거절하면 앱의 재전송 큐가 영영 비지 않는다.
 */

const REASONS: ReadonlySet<string> = new Set(['harmful', 'incorrect', 'other']);
const MAX_BODY_CHARS = 32_000;
const MESSAGE_MAX = 2000;
const PREV_USER_MAX = 1000;
const REPORTS_KEY = 'reports';
const REPORTS_KEEP = 2000;

function badRequest(message: string): Response {
  return json({ error: { code: 'bad_request', message } }, 400);
}

/** 문자열이면 max자로 자르고, 아니면 null. */
function clip(v: unknown, max: number): string | null {
  return typeof v === 'string' && v.length > 0 ? v.slice(0, max) : null;
}

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'POST') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const idOrErr = requireDeviceId(req);
  if (idOrErr instanceof Response) return idOrErr;

  const text = await req.text();
  if (text.length > MAX_BODY_CHARS) {
    return json({ error: { code: 'payload_too_large', message: 'Report too large' } }, 413);
  }
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    return json({ error: { code: 'bad_json', message: 'Invalid JSON body' } }, 400);
  }
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
    return badRequest('JSON object body required');
  }
  const b = raw as Record<string, unknown>;
  if (typeof b.reason !== 'string' || !REASONS.has(b.reason)) {
    return badRequest('reason must be harmful|incorrect|other');
  }
  if (typeof b.message !== 'string' || b.message.trim().length === 0) {
    return badRequest('message required');
  }

  const deviceHash = await sha256Hex(idOrErr);
  const prevUser = clip(b.prevUser, PREV_USER_MAX);
  const report = {
    ts: new Date().toISOString(),
    reason: b.reason,
    message: b.message.slice(0, MESSAGE_MAX),
    prevUser,
    provider: clip(b.provider, 64),
    model: clip(b.model, 128),
    appVersion: clip(b.appVersion, 32),
    locale: clip(b.locale, 16),
    truncated:
      b.message.length > MESSAGE_MAX ||
      (typeof b.prevUser === 'string' && b.prevUser.length > PREV_USER_MAX),
    device: deviceHash,
  };

  const limit = envInt('REPORT_DAILY_LIMIT', 20);
  try {
    const redis = upstashEnv();
    // 검증을 통과한 신고만 센다.
    const [used] = await incrementDaily(redis, [dailyKey('rpt', deviceHash.slice(0, 32))]);
    if (used > limit) {
      return json(
        { error: { code: 'report_rate_limited', message: 'Too many reports today.' } },
        429,
        { 'Retry-After': String(secondsUntilReset()) }
      );
    }
    await redisPipeline(redis, [
      ['LPUSH', REPORTS_KEY, JSON.stringify(report)],
      ['LTRIM', REPORTS_KEY, 0, REPORTS_KEEP - 1],
    ]);
  } catch (e: any) {
    console.log('[report] error:', e?.message);
    return json({ error: { code: 'internal', message: 'Report storage unavailable' } }, 500);
  }

  console.log(`[report] reason=${report.reason} provider=${report.provider ?? '-'}`);
  return json({ ok: true });
}
