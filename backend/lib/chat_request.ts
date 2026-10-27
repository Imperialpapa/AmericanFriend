/**
 * /chat/completions 요청 검증 + 업스트림 바디 화이트리스트 재구성.
 *
 * 클라이언트 바디를 그대로 넘기면 max_tokens·reasoning_effort·tools 같은 필드로
 * 업스트림 비용을 클라이언트가 정하게 된다(tobe S-05). 여기서 통과한 필드만
 * 업스트림으로 간다. 검증은 쿼터 INCR보다 먼저 한다 — 잘못된 요청이 한도를 깎지 않게.
 */

import { json } from './common';

export type ChatRole = 'system' | 'user' | 'assistant';

export interface ChatMessage {
  role: ChatRole;
  content: string;
}

export interface ChatRequest {
  messages: ChatMessage[];
  stream: boolean;
  /** 업스트림 출력 상한. 제공자별 필드명으로 바꿔 보낸다. */
  maxTokens: number;
}

export const CHAT_LIMITS = {
  maxMessages: 60,
  maxMessageChars: 8000,
  maxTotalChars: 40000,
  maxOutputTokens: 1024,
} as const;

const ROLES: ReadonlySet<string> = new Set(['system', 'user', 'assistant']);

export type ParseChatResult =
  | { ok: true; value: ChatRequest; trimmed: number }
  | { ok: false; response: Response };

function badRequest(message: string): ParseChatResult {
  return { ok: false, response: json({ error: { code: 'bad_request', message } }, 400) };
}

function tooLarge(message: string): ParseChatResult {
  return { ok: false, response: json({ error: { code: 'payload_too_large', message } }, 413) };
}

export function parseChatRequest(raw: unknown): ParseChatResult {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) {
    return badRequest('JSON object body required');
  }
  const body = raw as Record<string, unknown>;

  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return badRequest('messages[] required');
  }

  const system: ChatMessage[] = [];
  const turns: ChatMessage[] = [];
  for (let i = 0; i < body.messages.length; i++) {
    const m = body.messages[i] as Record<string, unknown> | null;
    if (typeof m !== 'object' || m === null) return badRequest(`messages[${i}] must be an object`);
    if (typeof m.role !== 'string' || !ROLES.has(m.role)) {
      return badRequest(`messages[${i}].role must be system|user|assistant`);
    }
    if (typeof m.content !== 'string') return badRequest(`messages[${i}].content must be a string`);
    // role/content 외 필드(name, tool_calls 등)는 버린다.
    const msg: ChatMessage = { role: m.role as ChatRole, content: m.content };
    (msg.role === 'system' ? system : turns).push(msg);
  }

  if (body.stream !== undefined && typeof body.stream !== 'boolean') {
    return badRequest('stream must be a boolean');
  }

  const requested = body.max_completion_tokens ?? body.max_tokens;
  let maxTokens: number = CHAT_LIMITS.maxOutputTokens;
  if (requested !== undefined && requested !== null) {
    if (typeof requested !== 'number' || !Number.isInteger(requested) || requested < 1) {
      return badRequest('max_tokens must be a positive integer');
    }
    maxTokens = Math.min(requested, CHAT_LIMITS.maxOutputTokens);
  }

  let systemChars = 0;
  for (const m of system) {
    if (m.content.length > CHAT_LIMITS.maxMessageChars) {
      return tooLarge(`system message exceeds ${CHAT_LIMITS.maxMessageChars} chars`);
    }
    systemChars += m.content.length;
  }

  // 앱은 대화 전체를 매번 보낸다(히스토리 윈도우 없음, tobe S-02). 개수·총량 초과로
  // 413을 주면 긴 대화가 그 뒤로 영영 실패하므로, 최근 턴부터 예산 안에서 자르고
  // 줄일 수 없는 부분(system + 마지막 메시지)이 넘칠 때만 413.
  const slots = CHAT_LIMITS.maxMessages - system.length;
  const charBudget = CHAT_LIMITS.maxTotalChars - systemChars;
  if (slots < 1 || charBudget < 0) {
    return tooLarge('system messages exceed the request budget');
  }

  const kept: ChatMessage[] = [];
  let used = 0;
  for (let i = turns.length - 1; i >= 0; i--) {
    const m = turns[i];
    const newest = kept.length === 0;
    const len = m.content.length;
    if (len > CHAT_LIMITS.maxMessageChars || used + len > charBudget) {
      if (newest) return tooLarge('last message exceeds the request budget');
      break; // 연속된 최근 구간만 남긴다.
    }
    if (kept.length >= slots) break;
    kept.push(m);
    used += len;
  }
  kept.reverse();

  return {
    ok: true,
    value: {
      messages: [...system, ...kept],
      stream: body.stream === true,
      maxTokens,
    },
    trimmed: turns.length - kept.length,
  };
}
