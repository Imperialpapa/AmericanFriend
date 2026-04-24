import { corsPreflight, json, requireDeviceId, CORS_HEADERS } from '../../../lib/common';
import { checkAndIncrement, upstashEnv } from '../../../lib/ratelimit';
import { callGemini } from '../../../lib/gemini';
import { callOpenAiCompat } from '../../../lib/openai_compat';

export const config = { runtime: 'edge' };

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'POST') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const idOrErr = requireDeviceId(req);
  if (idOrErr instanceof Response) return idOrErr;
  const deviceId = idOrErr;

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

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: { code: 'bad_json', message: 'Invalid JSON body' } }, 400);
  }
  if (!Array.isArray(body?.messages) || body.messages.length === 0) {
    return json({ error: { code: 'bad_request', message: 'messages[] required' } }, 400);
  }

  try {
    console.log(`[req] stream=${!!body.stream} msgs=${body.messages.length}`);
  } catch (_) {}

  const rlHeaders: Record<string, string> = {
    'X-RateLimit-Limit': String(rl.limit),
    'X-RateLimit-Remaining': String(rl.remaining),
    'X-RateLimit-Reset': rl.resetAt,
    ...CORS_HEADERS,
  };

  const provider = (process.env.UPSTREAM_PROVIDER ?? 'gemini').toLowerCase();
  const model =
    process.env.UPSTREAM_MODEL ??
    (provider === 'gemini' ? 'gemini-2.5-flash' : 'llama-3.3-70b-versatile');

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
