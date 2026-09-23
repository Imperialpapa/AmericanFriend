/**
 * API 응답 공용 헬퍼 + CORS.
 */

export const DEVICE_HEADER = 'x-device-id';

export const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': `content-type,${DEVICE_HEADER}`,
  'Access-Control-Max-Age': '86400',
};

export function json(
  data: unknown,
  status = 200,
  extra: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS, ...extra },
  });
}

export function requireDeviceId(req: Request): string | Response {
  const id = req.headers.get(DEVICE_HEADER);
  if (!id || id.length < 8 || id.length > 128) {
    return json(
      {
        error: {
          code: 'missing_device_id',
          message: `Header ${DEVICE_HEADER} required`,
        },
      },
      400
    );
  }
  return id;
}

export function corsPreflight(): Response {
  return new Response(null, { headers: CORS_HEADERS });
}

/** 비었거나 숫자가 아니면 기본값. 0은 유효하다(그 한도로 전부 차단 = 킬 스위치). */
export function envInt(name: string, fallback: number): number {
  const raw = process.env[name]?.trim();
  if (!raw) return fallback;
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

/** Vercel이 덮어써 주는 x-real-ip, 없으면 x-forwarded-for 첫 값. */
export function clientIp(req: Request): string {
  const real = req.headers.get('x-real-ip')?.trim();
  if (real) return real;
  const fwd = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  return fwd || 'unknown';
}

/**
 * IPv6는 /64(보통 가입자 1명) 단위로 묶는다. 주소 하나씩 바꿔 가며
 * IP 한도를 피하는 것을 막기 위함.
 */
export function ipBucket(raw: string): string {
  const ip = raw.trim().toLowerCase().replace(/%.*$/, '');
  if (!ip.includes(':')) return ip;
  const mapped = ip.match(/^::ffff:(\d{1,3}(?:\.\d{1,3}){3})$/);
  if (mapped) return mapped[1];
  const halves = ip.split('::');
  if (halves.length > 2) return ip;
  const head = halves[0] ? halves[0].split(':') : [];
  const tail = halves.length === 2 && halves[1] ? halves[1].split(':') : [];
  // 끝에 붙은 IPv4 표기(a.b.c.d)는 두 그룹을 차지한다.
  const width = (gs: string[]) => gs.reduce((n, g) => n + (g.includes('.') ? 2 : 1), 0);
  const fill = halves.length === 2 ? Math.max(0, 8 - width(head) - width(tail)) : 0;
  const groups = [...head, ...Array<string>(fill).fill('0'), ...tail];
  const prefix = groups
    .slice(0, 4)
    .map((g) => (parseInt(g, 16) || 0).toString(16))
    .join(':');
  return `${prefix}::/64`;
}

export async function sha256Hex(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, '0')).join('');
}
