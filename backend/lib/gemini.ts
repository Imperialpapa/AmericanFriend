/**
 * Gemini 어댑터 — OpenAI 호환 요청/응답으로 감쌈.
 * Vercel US 리전에서 실행되면 Gemini 지역 제한 회피됨.
 */

const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta';

export interface CallResult {
  response: Response;
  usedModel: string;
}

export async function callGemini(
  body: any,
  apiKey: string,
  model: string,
  extraHeaders: Record<string, string>
): Promise<CallResult> {
  const stream = !!body.stream;
  const gemBody = openAiToGemini(body.messages);
  const endpoint = stream
    ? `${GEMINI_BASE}/models/${model}:streamGenerateContent?alt=sse&key=${apiKey}`
    : `${GEMINI_BASE}/models/${model}:generateContent?key=${apiKey}`;

  const upstream = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(gemBody),
  });

  console.log(`[gemini] model=${model} status=${upstream.status} stream=${stream}`);

  if (!upstream.ok) {
    try {
      const cloned = upstream.clone();
      const text = await cloned.text();
      console.log(`[gemini] non-ok body: ${text.substring(0, 500)}`);
    } catch (_) {}
    return { response: forward(upstream, extraHeaders), usedModel: model };
  }

  if (stream) {
    const openAiStream = geminiSseToOpenAiSse(upstream.body!, model);
    return {
      response: new Response(openAiStream, {
        status: 200,
        headers: {
          'Content-Type': 'text/event-stream; charset=utf-8',
          'Cache-Control': 'no-cache',
          ...extraHeaders,
        },
      }),
      usedModel: model,
    };
  }

  const gemJson = (await upstream.json()) as any;
  const openAiJson = geminiToOpenAiCompletion(gemJson, model);
  return {
    response: new Response(JSON.stringify(openAiJson), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...extraHeaders },
    }),
    usedModel: model,
  };
}

function openAiToGemini(messages: Array<{ role: string; content: string }>): any {
  const contents: any[] = [];
  let systemInstruction: any = undefined;
  for (const msg of messages) {
    if (msg.role === 'system') {
      const text = msg.content;
      if (systemInstruction) systemInstruction.parts[0].text += '\n\n' + text;
      else systemInstruction = { parts: [{ text }] };
      continue;
    }
    const role = msg.role === 'assistant' ? 'model' : 'user';
    contents.push({ role, parts: [{ text: msg.content }] });
  }
  const out: any = { contents };
  if (systemInstruction) out.systemInstruction = systemInstruction;
  return out;
}

function geminiToOpenAiCompletion(gem: any, model: string): any {
  const text =
    gem?.candidates?.[0]?.content?.parts
      ?.map((p: any) => p.text ?? '')
      .join('') ?? '';
  return {
    id: `chatcmpl-${crypto.randomUUID()}`,
    object: 'chat.completion',
    created: Math.floor(Date.now() / 1000),
    model,
    choices: [
      {
        index: 0,
        message: { role: 'assistant', content: text },
        finish_reason: 'stop',
      },
    ],
    usage: gem?.usageMetadata
      ? {
          prompt_tokens: gem.usageMetadata.promptTokenCount ?? 0,
          completion_tokens: gem.usageMetadata.candidatesTokenCount ?? 0,
          total_tokens: gem.usageMetadata.totalTokenCount ?? 0,
        }
      : undefined,
  };
}

function geminiSseToOpenAiSse(
  geminiStream: ReadableStream<Uint8Array>,
  model: string
): ReadableStream<Uint8Array> {
  const id = `chatcmpl-${crypto.randomUUID()}`;
  const created = Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  return new ReadableStream<Uint8Array>({
    async start(controller) {
      const reader = geminiStream.getReader();
      let buffer = '';
      let firstChunk = true;

      function emit(chunk: any) {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`));
      }

      try {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
          const chunk = decoder.decode(value, { stream: true });
          console.log(`[gemini-sse-raw] ${chunk.substring(0, 500)}`);
          buffer += chunk;

          const events = buffer.split('\n\n');
          buffer = events.pop() ?? '';

          for (const event of events) {
            const dataLines = event
              .split('\n')
              .filter((l) => l.startsWith('data: '))
              .map((l) => l.substring(6));
            if (dataLines.length === 0) continue;
            const payload = dataLines.join('');
            if (!payload || payload.trim() === '[DONE]') continue;

            try {
              const gem = JSON.parse(payload);
              console.log(`[gemini-sse-parsed] keys=${Object.keys(gem).join(',')} candidates=${gem?.candidates?.length ?? 0}`);
              const text =
                gem?.candidates?.[0]?.content?.parts
                  ?.map((p: any) => p.text ?? '')
                  .join('') ?? '';
              console.log(`[gemini-sse-text] "${text.substring(0, 100)}"`);
              if (!text) continue;

              if (firstChunk) {
                emit({
                  id,
                  object: 'chat.completion.chunk',
                  created,
                  model,
                  choices: [
                    {
                      index: 0,
                      delta: { role: 'assistant', content: '' },
                      finish_reason: null,
                    },
                  ],
                });
                firstChunk = false;
              }

              emit({
                id,
                object: 'chat.completion.chunk',
                created,
                model,
                choices: [
                  { index: 0, delta: { content: text }, finish_reason: null },
                ],
              });
            } catch (e) {
              console.log('[gemini] sse parse error:', e);
            }
          }
        }

        emit({
          id,
          object: 'chat.completion.chunk',
          created,
          model,
          choices: [{ index: 0, delta: {}, finish_reason: 'stop' }],
        });
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
      } catch (e) {
        console.log('[gemini] stream error:', e);
      } finally {
        controller.close();
      }
    },
  });
}

function forward(res: Response, extra: Record<string, string>): Response {
  const headers = new Headers(res.headers);
  for (const [k, v] of Object.entries(extra)) headers.set(k, v);
  return new Response(res.body, {
    status: res.status,
    statusText: res.statusText,
    headers,
  });
}
