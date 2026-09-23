import {
  corsPreflight,
  json,
  requireDeviceId,
  CORS_HEADERS,
  clientIp,
  envInt,
  ipBucket,
  sha256Hex,
} from '../../../lib/common';
import {
  admitFreeTier,
  refund,
  secondsUntilReset,
  upstashEnv,
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

  const limits = {
    device: parseInt(process.env.FREE_DAILY_LIMIT ?? '20', 10) || 20,
    ip: envInt('FREE_IP_DAILY_LIMIT', 150),
    global: envInt('FREE_GLOBAL_DAILY_LIMIT', 2000),
  };
  // IP 원문은 저장하지 않는다 — 키에는 해시 앞부분만.
  const ipId = (await sha256Hex(ipBucket(clientIp(req)))).slice(0, 32);

  let redis: UpstashEnv;
  let admission;
  try {
    redis = upstashEnv();
    admission = await admitFreeTier(redis, deviceId, ipId, limits);
  } catch (e: any) {
    console.log('[rate-limit] error:', e?.message);
    return json(
      { error: { code: 'internal', message: 'Rate limiter unavailable' } },
      500
    );
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

  if (admission.kind === 'global_limited') {
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

  // 업스트림이 첫 바이트 전에 실패하면 이 요청의 차감을 모두 되돌린다(tobe S-06).
  const charged = admission.charged;

  const rlHeaders: Record<string, string> = {
    'X-RateLimit-Limit': String(rl.limit),
    'X-RateLimit-Remaining': String(rl.remaining),
    'X-RateLimit-Reset': rl.resetAt,
    ...CORS_HEADERS,
  };

  const provider = (process.env.UPSTREAM_PROVIDER ?? 'gemini').toLowerCase();
  // Groq deprecated llama-3.3-70b-versatile and llama-3.1-8b-instant on 2026-06-17;
  // calling them now returns 404 model_not_found. Groq's own recommended
  // replacement is openai/gpt-oss-120b.
  const model =
    process.env.UPSTREAM_MODEL ??
    (provider === 'gemini' ? 'gemini-2.5-flash' : 'openai/gpt-oss-120b');

  try {
    let result;
    if (provider === 'gemini') {
      const key = process.env.GEMINI_API_KEY;
      if (!key) throw new Error('GEMINI_API_KEY not set');
      result = await callGemini(body, key, model, rlHeaders);
    } else if (provider === 'groq') {
      const key = process.env.GROQ_API_KEY;
      if (!key) throw new Error('GROQ_API_KEY not set');
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
    } else if (provider === 'openrouter') {
      const key = process.env.OPENROUTER_API_KEY;
      if (!key) throw new Error('OPENROUTER_API_KEY not set');
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
    } else {
      await refund(redis, charged);
      return json({ error: { code: 'bad_provider', message: `Unknown provider: ${provider}` } }, 500);
    }
    if (!result.response.ok) await refund(redis, charged);
    return result.response;
  } catch (e: any) {
    console.log('[upstream] error:', e?.message);
    await refund(redis, charged);
    return json(
      { error: { code: 'upstream_error', message: e?.message ?? 'Upstream failed' } },
      502
    );
  }
}
