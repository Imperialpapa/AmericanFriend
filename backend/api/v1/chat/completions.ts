import { corsPreflight, json, requireDeviceId, CORS_HEADERS } from '../../../lib/common';
import { checkAndIncrement, upstashEnv } from '../../../lib/ratelimit';
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

  const limit = parseInt(process.env.FREE_DAILY_LIMIT ?? '20', 10) || 20;

  let rl;
  try {
    rl = await checkAndIncrement(upstashEnv(), deviceId, limit);
  } catch (e: any) {
    console.log('[rate-limit] error:', e?.message);
    return json(
      { error: { code: 'internal', message: 'Rate limiter unavailable' } },
      500
    );
  }

  if (!rl.allowed) {
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
      return json({ error: { code: 'bad_provider', message: `Unknown provider: ${provider}` } }, 500);
    }
    return result.response;
  } catch (e: any) {
    console.log('[upstream] error:', e?.message);
    return json(
      { error: { code: 'upstream_error', message: e?.message ?? 'Upstream failed' } },
      502
    );
  }
}
