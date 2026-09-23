import { json, corsPreflight, safeEqual, secretEnv } from '../../lib/common';

export const config = { runtime: 'edge' };

/**
 * 앱 상태/공지 엔드포인트.
 *
 * 존재 이유: 2026-08-16 Groq가 llama-3.3-70b-versatile을 셧다운하면서 무료 티어가
 * 전면 중단됐는데(BUG_HISTORY #9), 앱에는 그 사실을 사용자에게 알리거나
 * 앱 배포 없이 고칠 통로가 전혀 없었다. 이 엔드포인트가 그 통로다.
 *
 * 여기서 내려주는 값은 전부 **Vercel 환경변수로 제어**한다 — 코드 재배포 없이
 * 대시보드에서 바꾸고 저장하면 즉시 모든 설치본에 반영된다.
 *
 *   MIN_SUPPORTED_VERSION   예) "2.5.0"  이보다 낮은 앱에 업데이트 안내를 띄운다
 *   STATUS_NOTICE_JSON      공지 1건 (아래 Notice 형태). 비우면 공지 없음
 *   MODEL_MIGRATIONS_JSON   죽은 model ID → 살아있는 ID 매핑.
 *                           앱이 이걸 받아 저장된 설정을 스스로 교정한다.
 *                           제공자가 모델을 내려도 앱 릴리스 없이 복구된다.
 *
 * 무료 티어 실동작 확인(probe)은 기본 비활성이다. 앱이 켜질 때마다 실제 completion을
 * 호출하면 업스트림 쿼터를 갉아먹기 때문. 모니터링에서만 ?probe=1 로 호출할 것.
 * probe는 `x-monitor-token: $MONITOR_TOKEN` 헤더가 있어야 하고 `{ok, code}`만 준다 —
 * 업스트림 오류 원문은 공개 응답에 싣지 않는다(tobe S-04).
 */

type Localized = { ko?: string; en?: string };

type Notice = {
  id: string;
  severity: 'info' | 'warning' | 'critical';
  title: Localized;
  body: Localized;
  actionUrl?: string;
};

type ProbeResult = { ok: boolean; code: string };

// Edge 인스턴스가 재사용되는 동안만 유지되는 best-effort 캐시.
let probeCache: (ProbeResult & { at: number }) | null = null;
const PROBE_TTL_MS = 5 * 60 * 1000;

function parseJsonEnv<T>(raw: string | undefined, fallback: T): T {
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    // 환경변수 오타로 status 전체가 죽으면 안 된다 — 조용히 기본값.
    return fallback;
  }
}

/** 실제 completion 1회로 무료 티어가 살아있는지 확인. */
async function probeUpstream(): Promise<ProbeResult> {
  const now = Date.now();
  if (probeCache && now - probeCache.at < PROBE_TTL_MS) {
    return { ok: probeCache.ok, code: probeCache.code };
  }

  // completions와 같이 기본값으로 추측하지 않는다(tobe S-17).
  const provider = process.env.UPSTREAM_PROVIDER?.trim().toLowerCase();
  // UPSTREAM_MODEL은 쉼표 체인일 수 있다 — 1순위 모델만 확인한다.
  const model = process.env.UPSTREAM_MODEL?.split(',')[0]?.trim();
  if (!provider || !model || !['gemini', 'groq', 'openrouter'].includes(provider)) {
    return { ok: false, code: 'misconfigured' };
  }

  let result: ProbeResult;
  try {
    if (provider === 'groq' || provider === 'openrouter') {
      const key =
        provider === 'groq'
          ? process.env.GROQ_API_KEY
          : process.env.OPENROUTER_API_KEY;
      if (!key) return cacheProbe({ ok: false, code: 'missing_key' }, now);
      const url =
        provider === 'groq'
          ? 'https://api.groq.com/openai/v1/chat/completions'
          : 'https://openrouter.ai/api/v1/chat/completions';
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${key}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          max_tokens: 1,
          messages: [{ role: 'user', content: 'ping' }],
        }),
      });
      result = probeResult(res);
    } else {
      const key = process.env.GEMINI_API_KEY;
      if (!key) return cacheProbe({ ok: false, code: 'missing_key' }, now);
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
          body: JSON.stringify({
            contents: [{ role: 'user', parts: [{ text: 'ping' }] }],
            generationConfig: { maxOutputTokens: 1 },
          }),
        }
      );
      result = probeResult(res);
    }
  } catch (e) {
    console.log('[probe] error:', String(e).slice(0, 200));
    result = { ok: false, code: 'network_error' };
  }

  return cacheProbe(result, now);
}

function probeResult(res: Response): ProbeResult {
  if (res.ok) return { ok: true, code: 'ok' };
  console.log(`[probe] upstream status=${res.status}`);
  return { ok: false, code: `upstream_${res.status}` };
}

function cacheProbe(result: ProbeResult, at: number): ProbeResult {
  probeCache = { ...result, at };
  return result;
}

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'GET') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const url = new URL(req.url);
  if (url.searchParams.get('probe') === '1') {
    const token = secretEnv('MONITOR_TOKEN');
    const given = req.headers.get('x-monitor-token') ?? '';
    if (token === undefined || !safeEqual(given, token)) {
      return json({ error: { code: 'unauthorized' } }, 401, { 'Cache-Control': 'no-store' });
    }
    const probe = await probeUpstream();
    const httpStatus = probe.ok ? 200 : probe.code === 'misconfigured' ? 500 : 503;
    return json({ ok: probe.ok, code: probe.code }, httpStatus, {
      'Cache-Control': 'no-store',
    });
  }

  const notice = parseJsonEnv<Notice | null>(process.env.STATUS_NOTICE_JSON, null);
  const modelMigrations = parseJsonEnv<Record<string, string>>(
    process.env.MODEL_MIGRATIONS_JSON,
    {}
  );

  const body: Record<string, unknown> = {
    ok: true,
    ts: Date.now(),
    minSupportedVersion: process.env.MIN_SUPPORTED_VERSION ?? null,
    notice,
    modelMigrations,
    upstreamModel: process.env.UPSTREAM_MODEL ?? null,
  };

  // 공지는 자주 바뀔 수 있으므로 짧게만 캐시.
  return json(body, 200, { 'Cache-Control': 'public, max-age=60' });
}
