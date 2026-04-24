import { json, corsPreflight } from '../lib/common';

export const config = { runtime: 'edge' };

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return corsPreflight();
  if (req.method !== 'GET') {
    return json({ error: { code: 'method_not_allowed' } }, 405);
  }
  return json({ ok: true, ts: Date.now() });
}
