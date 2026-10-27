/**
 * OpenAI 호환 엔드포인트 공용 호출 함수.
 * Groq, OpenRouter 등 모두 같은 스키마이므로 재사용.
 */

import type { ChatRequest } from './chat_request';

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
  /** 출력 상한 필드명. Groq는 max_tokens를 deprecated 처리했다. 기본 max_tokens. */
  maxTokensField?: 'max_tokens' | 'max_completion_tokens';
}

export async function callOpenAiCompat(
  body: ChatRequest,
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

/**
 * gpt-oss 계열은 추론(reasoning) 모델이라 기본값으로 두면 답변 전에 수백 토큰을
 * 속으로 생각한다. 음성 대화 앱에서는 사용자가 말을 마친 뒤 아무 소리도 안 나는
 * 침묵으로 나타난다.
 *
 * 실측(2026-08-18, "Hi, how are you today?" 한 문장):
 *   기본            reasoning 382자 / 110 tokens / 0.237s
 *   effort=low      reasoning  20자 /  26 tokens / 0.086s  ← 2.8배 빠름
 *   format=hidden   reasoning   0자 /  78 tokens / 0.166s  (감추기만 하고 계산은 함)
 *
 * `reasoning_effort: "none"`은 지원되지 않는다(에러).
 *
 * 클라이언트 값은 받지 않는다 — 추론 길이가 곧 업스트림 비용이다(tobe S-05).
 */
function buildUpstreamBody(
  body: ChatRequest,
  cfg: OpenAiCompatConfig,
  model: string
): Record<string, unknown> {
  const out: Record<string, unknown> = {
    model,
    messages: body.messages,
    stream: body.stream,
    [cfg.maxTokensField ?? 'max_tokens']: body.maxTokens,
  };
  if (/gpt-oss/i.test(model)) {
    out.reasoning_effort = process.env.UPSTREAM_REASONING_EFFORT ?? 'low';
  }
  return out;
}

async function fetchUpstream(
  body: ChatRequest,
  cfg: OpenAiCompatConfig,
  model: string
): Promise<Response> {
  const upstreamBody = buildUpstreamBody(body, cfg, model);
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
