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
- `POST /api/v1/report` — AI 응답 신고. Upstash 리스트 `reports`(최근 2000건)에 저장, 확인은 Upstash 콘솔 CLI `LRANGE reports 0 49`

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
| `UPSTREAM_PROVIDER` | `gemini` | 필수. 없으면 500 `misconfigured` |
| `UPSTREAM_MODEL` | `gemini-2.5-flash` | 필수. 없으면 500 `misconfigured` |
| `GEMINI_API_KEY` | (1번에서 발급한 키) | |
| `UPSTASH_REDIS_REST_URL` | (1번에서 복사) | |
| `UPSTASH_REDIS_REST_TOKEN` | (1번에서 복사) | |
| `FREE_DAILY_LIMIT` | `20` | 기기당 일 한도 |
| `FREE_IP_DAILY_LIMIT` | `150` | IP(IPv6는 /64)당 일 한도. 초과 시 429 `ip_rate_limited` |
| `FREE_GLOBAL_DAILY_LIMIT` | `2000` | 전체 일 한도(비용 상한). 초과 시 503 `free_tier_busy`. `0` = 무료 티어 차단 |
| `MONITOR_DEVICE_ID` | 32자 이상 랜덤 | 모니터 전용 device-id(기기·IP·전역 한도 면제). GitHub secret `MONITOR_DEVICE_ID`와 같은 값. 32자 미만이면 무시 |
| `MONITOR_TOKEN` | 32자 이상 랜덤 | `/api/v1/status?probe=1`의 `x-monitor-token` 헤더 값. 없으면 probe는 401 |
| `REPORT_DAILY_LIMIT` | `20` | 기기당 일 신고 한도(채팅 한도와 별개) |

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
- **Upstash Free**: 월 50만 commands. 파이프라인 안의 명령도 하나씩 센다
- **Gemini Flash**: 1,500 req/일 무료 → 75 DAU × 20 msg 수용
- **Total**: 소규모 런칭엔 **완전 무료**

### Upstash 명령 예산

리미터는 fail-closed다 — Upstash 월 한도가 차서 막히면 그달 남은 기간 무료 티어 전체가 500이 된다.

| 요청 | 명령 수 |
|---|---|
| 채팅 통과 | 3 (INCR 전역·IP·기기) + 그날 처음 생긴 키마다 EXPIRE 1 |
| 채팅 거절(IP·전역·기기 한도) | 5 (INCR 3 + DECR 2). 같은 인스턴스에 같은 키로 다시 오면 0 |
| 업스트림 실패 환불 | 통과 + DECR 3 |
| `/quota`, 모니터 | 1 (GET) |

월 추정 ≈ `FREE_GLOBAL_DAILY_LIMIT × 3 × 30` + (일 활성 기기 + IP) × 30 + 모니터 1,440 + `/quota`·신고.
기본 상한 2000이면 통과분만 18만(36%)이다. 상한을 올릴 땐 `상한 × 3 × 30`이 35만(70%)을 넘지 않게(≈ 3,900 이하), 넘으면 Pay-as-you-go로 바꾼다.
Upstash 콘솔 Usage에서 월 사용량을 확인하고, 사용량 알림을 설정할 수 있으면 70%로 둔다.

## Phase 2 확장 포인트

- [ ] Play Integrity API 검증
- [ ] 여러 업스트림 자동 failover (Gemini → Groq → OpenRouter)
- [ ] Analytics / 사용 통계
