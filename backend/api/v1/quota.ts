import { corsPreflight, json, requireDeviceId } from '../../lib/common';
import { peek, upstashEnv } from '../../lib/ratelimit';

export const config = { runtime: 'edge' };

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'GET') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }

  const idOrErr = requireDeviceId(req);
  if (idOrErr instanceof Response) return idOrErr;

  const limit = parseInt(process.env.FREE_DAILY_LIMIT ?? '20', 10) || 20;
  try {
    const result = await peek(upstashEnv(), idOrErr, limit);
    return json({
      limit: result.limit,
      remaining: result.remaining,
      used: result.used,
      resetAt: result.resetAt,
    });
  } catch (e: any) {
    return json(
      { error: { code: 'internal', message: e?.message ?? 'Internal error' } },
      500
    );
  }
}
