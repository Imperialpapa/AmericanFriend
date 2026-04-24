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
