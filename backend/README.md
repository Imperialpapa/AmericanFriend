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
| `UPSTREAM_PROVIDER` | `groq` | 필수. 없으면 500 `misconfigured` |
| `UPSTREAM_MODEL` | `openai/gpt-oss-120b,qwen/qwen3.8-27b,openai/gpt-oss-20b` | 필수. 쉼표 체인 — 앞 모델이 429·403·5xx·404면 다음 모델. 아래 "Upstream 제공자 변경" |
| `GROQ_API_KEY` | (Groq 콘솔에서 발급) | `GEMINI_API_KEY`·`OPENROUTER_API_KEY`는 그 제공자를 쓸 때만 |
| `UPSTASH_REDIS_REST_URL` | (1번에서 복사) | |
| `UPSTASH_REDIS_REST_TOKEN` | (1번에서 복사) | |
| `FREE_DAILY_LIMIT` | `20` | 기기당 일 한도 |
| `FREE_IP_DAILY_LIMIT` | `150` | IP(IPv6는 /64)당 일 한도. 초과 시 429 `ip_rate_limited` |
| `FREE_GLOBAL_DAILY_LIMIT` | `900` | 전체 일 한도(비용 상한). 초과 시 503 `free_tier_busy`. `0` = 무료 티어 차단. Groq Free(조직 1K RPD)에서는 900을 넘기지 않는다 — 아래 "비용 감" |
| `MONITOR_DEVICE_ID` | 32자 이상 랜덤 | 모니터 전용 device-id. 카운터를 올리지 않지만 Upstash 장애(500)·전역 한도 소진(503)은 실사용자와 같이 받는다. GitHub secret `MONITOR_DEVICE_ID`와 같은 값. 32자 미만이면 무시 |
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

### Groq (현재, 권장 — 2026-10-27 확인)
```
UPSTREAM_PROVIDER = groq
UPSTREAM_MODEL = openai/gpt-oss-120b,qwen/qwen3.8-27b,openai/gpt-oss-20b
GROQ_API_KEY = ...
```
- Groq Free 한도는 **모델마다** 30 RPM / 1K RPD / 8K TPM / 200K TPD(조직 전체 기준)라, 체인하면
  한 모델이 한도에 걸려도 다음 모델이 받는다. 모델별 한도가 실제로 따로인지는 응답의
  `x-ratelimit-*` 헤더로 확인한 뒤 `FREE_GLOBAL_DAILY_LIMIT`를 올린다.
- `qwen/qwen3.8-27b`는 Preview(예고 없이 내려갈 수 있음). 내려가면 404 → 체인이 다음 모델로 넘긴다.
  마지막은 안정 모델(gpt-oss-20b)로 둔다. reasoning은 gpt-oss만 `low`로 보내고 qwen은 기본(OFF).
- 체인 끝까지 429면 앱에는 503 `upstream_busy`로 준다(사용자 한도 429와 구분).
- 폐기된 ID(호출 시 404): `llama-3.3-70b-versatile`, `llama-3.1-8b-instant`, `qwen3-32b`, `llama-4-scout`,
  `qwen3.6-27b`, `compound`, `kimi-k2-0905`.

### Gemini — 유료 키만
```
UPSTREAM_PROVIDER = gemini
UPSTREAM_MODEL = gemini-3.5-flash-lite
GEMINI_API_KEY = ...
```
무료 티어 키는 쓰지 않는다. Gemini API 약관상 EEA·스위스·영국 사용자에게 제공하는 앱은 유료
서비스만 쓸 수 있고, 무료 티어 데이터는 제품 개선에 쓰인다. 18세 미만 대상 앱도 금지다(tobe S-17).

### OpenRouter — 유료 모델만
```
UPSTREAM_PROVIDER = openrouter
UPSTREAM_MODEL = <유료 모델 ID 체인>
OPENROUTER_API_KEY = ...
```
`:free` 모델은 프록시에 쓰지 않는다. 일 50회(크레딧 $10 구매 시 1,000회)이고, 일부는 운영 사용 금지
(NVIDIA 체험 약관)나 프롬프트 학습 조건이 붙는다. DeepSeek 무료판(`deepseek/deepseek-v4-flash:free`)도
마찬가지이며, DeepSeek 공식 API는 무료 티어가 없고 데이터를 중국 서버에서 처리한다.

## 로그 모니터링

Vercel 대시보드 → Project → **Logs** 탭에서 실시간 확인. 또는:
```powershell
npx vercel logs --follow
```

## 비용 감

- **Vercel Hobby**: 10만 호출/월, 100GB-hours/월 — 수천 DAU까지 무료
- **Upstash Free**: 월 50만 commands. 파이프라인 안의 명령도 하나씩 센다
- **Groq Free**(현재 업스트림, 2026-10-27 확인): 모델마다 **조직 전체** 30 RPM / 1K RPD / 8K TPM / 200K TPD.
  실질 병목은 TPD다 — 요청 1건이 프롬프트+히스토리+답변 합쳐 1.5K 토큰이면 모델당 하루 약 130건이다.
  넘어서면 유료(Developer) 전환: gpt-oss-120b 기준 약 $0.32 / 1K 요청(1.5K in·150 out 가정)
- **Total**: 소규모 런칭엔 **완전 무료**

### Groq Free 요청 예산

전역 상한은 업스트림 요청 수(RPD)를 지키는 값이다. 앱의 대화·제안·레벨 평가·발음 평가가 모두 1건씩 센다.

| 항목 | 요청/일 |
|---|---|
| 전역 상한 `FREE_GLOBAL_DAILY_LIMIT` | 900 |
| 모니터(GitHub Actions, 30분마다 1회·실패 시 2회) | 48~96 |
| 업스트림 재시도(1순위 모델 429·403·5xx 시 1회 더) | 장애 시에만 |
| **합계** | **1K RPD 미만** |

기기 한도 20이면 하루 45대가 한도를 다 쓰면 전역 상한에 닿는다. 상한은 모델 체인의 모델별 한도가
따로임을 `x-ratelimit-*` 헤더로 확인하거나 Groq 플랜을 올리기 전에는 올리지 않는다. 그 전에 TPD가 먼저 찰 수 있다.

### Upstash 명령 예산

리미터는 fail-closed다 — Upstash 월 한도가 차서 막히면 그달 남은 기간 무료 티어 전체가 500이 된다.

| 요청 | 명령 수 |
|---|---|
| 채팅 통과 | 3 (INCR 전역·IP·기기) + 그날 처음 생긴 키마다 EXPIRE 1 |
| 채팅 거절(IP·전역·기기 한도) | 5 (INCR 3 + DECR 2). 같은 인스턴스에 같은 키로 다시 오면 0 |
| 업스트림 실패 환불 | 통과 + DECR 1(기기). 5xx·네트워크 오류면 +1(전역). IP는 환불하지 않는다 |
| `/quota`, 모니터 | 1 (GET) |

월 추정 ≈ `FREE_GLOBAL_DAILY_LIMIT × 3 × 30` + (일 활성 기기 + IP) × 30 + 모니터 1,440 + `/quota`·신고.
기본 상한 900이면 통과분은 8.1만(16%)이다. 업스트림 플랜을 올려 상한도 올릴 땐 `상한 × 3 × 30`이 35만(70%)을 넘지 않게(≈ 3,900 이하), 넘으면 Pay-as-you-go로 바꾼다.
Upstash 콘솔 Usage에서 월 사용량을 확인하고, 사용량 알림을 설정할 수 있으면 70%로 둔다.

업스트림이 4xx(모델 셧다운 404, 413, 429 등)로 실패한 요청은 IP·전역 한도를 쓴다 — 매번 실패하는 요청으로 한도를 우회하지 못하게.
업스트림 429는 앱에 503 `upstream_busy`로 바꿔 준다. 그대로 넘기면 앱이 사용자 일일 한도 소진으로 읽는다.
모델 셧다운을 고친 뒤 같은 UTC 날짜에 503 `free_tier_busy`가 나면 Upstash 콘솔 CLI에서 `GET rlg:<YYYY-MM-DD>`로 확인하고 `DEL rlg:<YYYY-MM-DD>` 뒤 재배포한다(인스턴스 메모리의 거절 캐시도 비워야 풀린다).

## Phase 2 확장 포인트

- [ ] Play Integrity API 검증
- [ ] 여러 업스트림 자동 failover (Gemini → Groq → OpenRouter)
- [ ] Analytics / 사용 통계
