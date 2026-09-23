import {
  corsPreflight,
  json,
  requireDeviceId,
  CORS_HEADERS,
  clientIp,
  envInt,
  ipBucket,
  safeEqual,
  secretEnv,
  sha256Hex,
} from '../../../lib/common';
import {
  admitFreeTier,
  peekGlobal,
  refundFailedCall,
  secondsUntilReset,
  upstashEnv,
  type ChargedKeys,
  type UpstashEnv,
} from '../../../lib/ratelimit';
import { callGemini } from '../../../lib/gemini';
import { callOpenAiCompat } from '../../../lib/openai_compat';
import { parseChatRequest } from '../../../lib/chat_request';

export const config = { runtime: 'edge' };

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'POST') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const idOrErr = requireDeviceId(req);
  if (idOrErr instanceof Response) return idOrErr;
  const deviceId = idOrErr;

  // 검증·재구성은 INCR보다 먼저 — 잘못된 요청이 쿼터를 깎지 않게(tobe S-05).
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return json({ error: { code: 'bad_json', message: 'Invalid JSON body' } }, 400);
  }
  const parsed = parseChatRequest(raw);
  if (!parsed.ok) return parsed.response;
  const body = parsed.value;

  console.log(
    `[req] stream=${body.stream} msgs=${body.messages.length} trimmed=${parsed.trimmed}`
  );

  // 설정 오류는 한도를 깎기 전에 거른다.
  const upstream = resolveUpstream();
  if (upstream instanceof Response) return upstream;

  const admitted = await admit(req, deviceId);
  if (admitted instanceof Response) return admitted;
  // 업스트림이 첫 바이트 전에 실패하면 차감 일부를 되돌린다(tobe S-06, 범위는 refundFailedCall).
  const refundFailed = (status: number | null) =>
    admitted.charge
      ? refundFailedCall(admitted.charge.redis, admitted.charge.keys, status)
      : Promise.resolve();

  const rlHeaders: Record<string, string> = { ...admitted.headers, ...CORS_HEADERS };

  try {
    const { provider, model, key } = upstream;
    let result;
    if (provider === 'gemini') {
      result = await callGemini(body, key, model, rlHeaders);
    } else if (provider === 'groq') {
      result = await callOpenAiCompat(
        body,
        {
          url: 'https://api.groq.com/openai/v1/chat/completions',
          apiKey: key,
          modelChain: model,
          label: 'groq',
          maxTokensField: 'max_completion_tokens',
        },
        rlHeaders
      );
    } else {
      result = await callOpenAiCompat(
        body,
        {
          url: 'https://openrouter.ai/api/v1/chat/completions',
          apiKey: key,
          modelChain: model,
          label: 'openrouter',
          extraOutboundHeaders: {
            'HTTP-Referer': 'https://eng-friend-proxy.vercel.app',
            'X-Title': 'Eng Friend Free Tier',
          },
        },
        rlHeaders
      );
    }
    if (!result.response.ok) await refundFailed(result.response.status);
    return result.response;
  } catch (e: any) {
    console.log('[upstream] error:', e?.message);
    await refundFailed(null);
    return json(
      { error: { code: 'upstream_error', message: e?.message ?? 'Upstream failed' } },
      502
    );
  }
}

const PROVIDER_KEY_ENV = {
  gemini: 'GEMINI_API_KEY',
  groq: 'GROQ_API_KEY',
  openrouter: 'OPENROUTER_API_KEY',
} as const;

type Provider = keyof typeof PROVIDER_KEY_ENV;

interface Upstream {
  provider: Provider;
  model: string;
  key: string;
}

/**
 * env가 비면 코드 기본값(gemini)으로 추측하지 않고 500 misconfigured로 멈춘다.
 * 조용히 다른 제공자로 붙으면 모니터가 못 잡고, Gemini는 약관상 18세 미만
 * 이용 앱에 쓸 수 없다(tobe S-17). 원인은 서버 로그에만 남긴다.
 */
function resolveUpstream(): Upstream | Response {
  const provider = process.env.UPSTREAM_PROVIDER?.trim().toLowerCase();
  const model = process.env.UPSTREAM_MODEL?.trim();
  const keyEnv =
    provider && Object.hasOwn(PROVIDER_KEY_ENV, provider)
      ? PROVIDER_KEY_ENV[provider as Provider]
      : undefined;
  const key = keyEnv ? process.env[keyEnv] : undefined;
  if (!provider || !model || !keyEnv || !key) {
    console.log(
      `[config] misconfigured: provider=${provider || '-'} model=${model ? 'set' : '-'} key=${key ? 'set' : '-'}`
    );
    return json(
      { error: { code: 'misconfigured', message: 'Free tier is not configured' } },
      500
    );
  }
  return { provider: provider as Provider, model, key };
}

interface Admission {
  /** null이면 차감하지 않은 요청(모니터) — 환불할 것도 없다. */
  charge: { redis: UpstashEnv; keys: ChargedKeys } | null;
  headers: Record<string, string>;
}

function limiterUnavailable(e: any): Response {
  console.log('[rate-limit] error:', e?.message);
  return json({ error: { code: 'internal', message: 'Rate limiter unavailable' } }, 500);
}

function freeTierBusy(): Response {
  console.log('[rate-limit] global limit hit');
  return json(
    {
      error: {
        code: 'free_tier_busy',
        message: 'The free tier is at capacity today. Try again later or add your own API key.',
      },
    },
    503,
    { 'Retry-After': String(secondsUntilReset()) }
  );
}

/**
 * 모니터(GitHub Actions)는 30분마다 실경로를 호출하므로 카운터는 올리지 않는다(tobe S-04).
 * 그래도 Upstash는 실사용자처럼 거친다 — 리미터 장애·env 누락·전역 소진으로 실사용자가
 * 전원 막혔는데 모니터만 통과하면 BUG #9처럼 아무도 모른다. 30분에 GET 1개.
 */
async function admitMonitor(globalLimit: number): Promise<Admission | Response> {
  console.log('[req] monitor');
  let globalUsed: number;
  try {
    globalUsed = await peekGlobal(upstashEnv());
  } catch (e: any) {
    return limiterUnavailable(e);
  }
  // 실사용자는 INCR 뒤 `> limit`이면 거절되므로, 올리기 전 값이 limit 이상이면 전원 거절 중이다.
  if (globalUsed >= globalLimit) return freeTierBusy();
  return { charge: null, headers: {} };
}

/** 한도 판정. 통과하면 Admission, 거절이면 그대로 돌려줄 Response. */
async function admit(req: Request, deviceId: string): Promise<Admission | Response> {
  const limits = {
    device: parseInt(process.env.FREE_DAILY_LIMIT ?? '20', 10) || 20,
    ip: envInt('FREE_IP_DAILY_LIMIT', 150),
    global: envInt('FREE_GLOBAL_DAILY_LIMIT', 2000),
  };

  // 이 값을 아는 사람은 한도 없이 쓸 수 있다 — 짧은 값은 secretEnv가 무시한다.
  const monitorId = secretEnv('MONITOR_DEVICE_ID');
  if (monitorId !== undefined && safeEqual(deviceId, monitorId)) {
    return admitMonitor(limits.global);
  }

  // IP 원문은 저장하지 않는다 — 키에는 해시 앞부분만.
  const ipId = (await sha256Hex(ipBucket(clientIp(req)))).slice(0, 32);

  let redis: UpstashEnv;
  let admission;
  try {
    redis = upstashEnv();
    admission = await admitFreeTier(redis, deviceId, ipId, limits);
  } catch (e: any) {
    return limiterUnavailable(e);
  }

  if (admission.kind === 'ip_limited') {
    console.log('[rate-limit] ip limit hit');
    return json(
      {
        error: {
          code: 'ip_rate_limited',
          message: 'Too many free requests from this network today.',
        },
      },
      429,
      { 'Retry-After': String(secondsUntilReset()) }
    );
  }

  if (admission.kind === 'global_limited') return freeTierBusy();

  const rl = admission.device;
  if (admission.kind === 'device_limited') {
    return json(
      {
        error: {
          code: 'rate_limit_exceeded',
          message: 'Daily free limit reached. Add your own API key for unlimited usage.',
          limit: rl.limit,
          used: rl.used,
          resetAt: rl.resetAt,
        },
      },
      429,
      {
        'X-RateLimit-Limit': String(rl.limit),
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': rl.resetAt,
      }
    );
  }

  return {
    charge: { redis, keys: admission.charged },
    headers: {
      'X-RateLimit-Limit': String(rl.limit),
      'X-RateLimit-Remaining': String(rl.remaining),
      'X-RateLimit-Reset': rl.resetAt,
    },
  };
}
