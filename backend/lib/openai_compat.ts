/**
 * OpenAI 호환 엔드포인트 공용 호출 함수.
 * Groq, OpenRouter 등 모두 같은 스키마이므로 재사용.
 */

export interface CallResult {
  response: Response;
  usedModel: string;
}

export interface OpenAiCompatConfig {
  url: string;
  apiKey: string;
  modelChain: string; // 쉼표 구분: "model1,model2,model3"
  extraOutboundHeaders?: Record<string, string>;
  label: string; // 로그 구분 (e.g. 'groq', 'openrouter')
}

export async function callOpenAiCompat(
  body: any,
  cfg: OpenAiCompatConfig,
  extraResponseHeaders: Record<string, string>
): Promise<CallResult> {
  const models = cfg.modelChain
    .split(',')
    .map((m) => m.trim())
    .filter((m) => m.length > 0);
  if (models.length === 0) throw new Error(`${cfg.label}: empty model chain`);

  let lastResponse: Response | null = null;

  for (let i = 0; i < models.length; i++) {
    const model = models[i];
    const attempts = i === 0 ? 2 : 1;
    for (let a = 0; a < attempts; a++) {
      if (a > 0) await sleep(400);
      const res = await fetchUpstream(body, cfg, model);
      console.log(
        `[${cfg.label}] model=${model} attempt=${a + 1}/${attempts} status=${res.status}`
      );
      if (res.ok) {
        return { response: withHeaders(res, extraResponseHeaders), usedModel: model };
      }
      lastResponse = res;
      const retriable = res.status === 429 || res.status === 403 || res.status >= 500;
      if (!retriable) break;
    }
    await sleep(200);
  }

  if (lastResponse) {
    try {
      const cloned = lastResponse.clone();
      const text = await cloned.text();
      console.log(`[${cfg.label}] final non-ok body: ${text.substring(0, 500)}`);
    } catch (_) {}
    return { response: withHeaders(lastResponse, extraResponseHeaders), usedModel: models[0] };
  }

  throw new Error(`${cfg.label}: no response`);
}

async function fetchUpstream(
  body: any,
  cfg: OpenAiCompatConfig,
  model: string
): Promise<Response> {
  const upstreamBody = { ...body, model };
  return fetch(cfg.url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${cfg.apiKey}`,
      'Content-Type': 'application/json',
      Accept: body.stream ? 'text/event-stream' : 'application/json',
      ...(cfg.extraOutboundHeaders ?? {}),
    },
    body: JSON.stringify(upstreamBody),
  });
}

function withHeaders(res: Response, extra: Record<string, string>): Response {
  const headers = new Headers(res.headers);
  for (const [k, v] of Object.entries(extra)) headers.set(k, v);
  return new Response(res.body, {
    status: res.status,
    statusText: res.statusText,
    headers,
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
