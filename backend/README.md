# Eng-Friend Free Tier Proxy (Vercel)

Vercel Edge Functions 기반 프록시. Flutter 앱이 이 프록시를 통해 LLM API를 호출하므로 API 키가 앱에 노출되지 않음.

## 아키텍처

```
Flutter App
  ↓ POST /api/v1/chat/completions
  ↓ x-device-id: <uuid>
Vercel Edge Function (US region)
  ↓ rate limit check (Upstash Redis)
  ↓ LLM 호출 (Gemini / Groq / OpenRouter)
Upstream LLM
```

**핵심**: Vercel은 US 리전에서 실행 → Gemini/Groq 지역 제한 회피됨.

- 한도: `FREE_DAILY_LIMIT` (기본 20)/기기/UTC 일
- 상태: Upstash Redis
- 응답: OpenAI 호환 (스트리밍 포함)

## 엔드포인트

- `GET  /api/healthz` — health check
- `GET  /api/v1/quota` — 현재 기기 사용량 조회 (`x-device-id` 헤더 필요)
- `POST /api/v1/chat/completions` — 채팅 (OpenAI 호환)

## 최초 1회 배포

### 1. Upstash Redis 생성
[upstash.com](https://upstash.com) → 구글 로그인 → **Create Database**
- Name: `eng-friend-ratelimit`
- Type: Regional (Global은 유료)
- Region: **us-east-1** (Vercel과 동일 리전이 빠름)

생성 후 **Details** 탭의:
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

두 값을 복사해두기.

### 2. Gemini API 키
[aistudio.google.com/apikey](https://aistudio.google.com/apikey) — **Create API Key**.

### 3. GitHub 리포지터리 push
프로젝트 루트에서:
```powershell
git add backend/
git commit -m "feat(backend): Vercel proxy"
git push
```

### 4. Vercel에 Import
[vercel.com/new](https://vercel.com/new) → GitHub 로그인 → `english` 리포 선택

**Important**: "Root Directory" 설정에 **`backend`** 지정.

### 5. 환경변수 설정
Vercel 프로젝트 → **Settings → Environment Variables**에서 추가:

| Key | Value | Notes |
|---|---|---|
| `UPSTREAM_PROVIDER` | `gemini` | |
| `UPSTREAM_MODEL` | `gemini-2.5-flash` | |
| `GEMINI_API_KEY` | (1번에서 발급한 키) | |
| `UPSTASH_REDIS_REST_URL` | (1번에서 복사) | |
| `UPSTASH_REDIS_REST_TOKEN` | (1번에서 복사) | |
| `FREE_DAILY_LIMIT` | `20` | 기기당 일 한도 |

Production / Preview / Development 모두 체크.

### 6. Deploy 버튼 클릭
자동 배포. 완료되면 `https://<your-app>.vercel.app` URL 생성.

### 7. 테스트
```powershell
curl https://<your-app>.vercel.app/api/healthz

curl -H "x-device-id: test-xxx" `
  https://<your-app>.vercel.app/api/v1/quota

curl -X POST `
  -H "x-device-id: test-xxx" `
  -H "content-type: application/json" `
  -d '{\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}' `
  https://<your-app>.vercel.app/api/v1/chat/completions
```

## Flutter 앱 연결

`lib/core/config/proxy_config.dart`의 `defaultValue`를 Vercel URL로 변경:
```dart
defaultValue: 'https://<your-app>.vercel.app',
```
(말미에 슬래시 없이)

그리고 `free_tier_ai_service.dart`의 경로는 `/api/v1/chat/completions` 형태라서 그대로 동작.

## Upstream 제공자 변경

### Gemini (기본)
```
UPSTREAM_PROVIDER = gemini
UPSTREAM_MODEL = gemini-2.5-flash
GEMINI_API_KEY = ...
```

### Groq (OpenAI 호환)
```
UPSTREAM_PROVIDER = groq
UPSTREAM_MODEL = llama-3.3-70b-versatile
GROQ_API_KEY = ...
```

### OpenRouter (다중 무료 모델 체인)
```
UPSTREAM_PROVIDER = openrouter
UPSTREAM_MODEL = meta-llama/llama-3.3-70b-instruct:free,google/gemma-3-27b-it:free
OPENROUTER_API_KEY = ...
```

## 로그 모니터링

Vercel 대시보드 → Project → **Logs** 탭에서 실시간 확인. 또는:
```powershell
npx vercel logs --follow
```

## 비용 감

- **Vercel Hobby**: 10만 호출/월, 100GB-hours/월 — 수천 DAU까지 무료
- **Upstash Free**: 1만 commands/일 — 사용자당 2~3 commands/요청 → 3,000~5,000 req/일 수용
- **Gemini Flash**: 1,500 req/일 무료 → 75 DAU × 20 msg 수용
- **Total**: 소규모 런칭엔 **완전 무료**

## Phase 2 확장 포인트

- [ ] Play Integrity API 검증
- [ ] 여러 업스트림 자동 failover (Gemini → Groq → OpenRouter)
- [ ] Analytics / 사용 통계
