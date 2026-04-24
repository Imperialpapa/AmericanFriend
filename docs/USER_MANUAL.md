# Korean Friend - User Manual

AI tutor Alex와 자연스러운 대화를 통해 외국어를 배우는 앱입니다.
9개 언어를 지원하며, 모국어와 대상 언어를 자유롭게 선택할 수 있습니다.

> **v2.3.0 업데이트 (2026-04)**
>
> - **무료 체험 내장** — API 키 없이 하루 20회 무료 대화 가능 (Vercel 프록시 + Groq)
> - **UI 한/영 자동 전환** — 설정의 모국어가 한국어면 UI도 한글, 그 외는 영어
> - **스마트 마이크** — 말 도중 최대 5초 멈춤 허용, 자동 전송 끄기 옵션
> - **온보딩 3단계로 간소화** — Welcome → Language → Level (API 키 입력 제거, 필요 시 설정에서)
> - **Learning Drawer 항상 접근 가능** — 듣기/따라하기/저장 버튼이 모든 AI 답변에서 작동
> - **사용자 메시지 발음 연습** — 본인이 보낸 메시지도 길게 눌러 연습·단어장 저장
> - **시작 오류 자동 복구** — 보안 저장소 손상 시 복구 옵션 제공
>
> 기반 디자인: **Modern Sage** (sage 그린 + 베이지 + 머스타드 톤, Alex 페블 마스코트).

---

## Getting Started

### First Launch (Onboarding) — 3단계
1. **Welcome** — Alex 페블 마스코트와 인사 (sage 강조 헤드라인)
2. **Language Setup** — 모국어는 기기 설정에서 자동 감지. 확인 후 학습할 언어 선택. 두 언어가 같으면 경고 표시.
3. **Level Selection** — 1-10 슬라이더로 대략적 레벨 선택. 대화하면서 자동 보정됨.

진행 상태는 상단의 **도트 프로그레스**(● ─ ─)와 하단의 "Step X of 3" 로 표시. sage 컬러의 Continue 버튼을 탭해 다음 단계로.

온보딩 끝나면 **바로 채팅 가능** — 별도 API 키 입력 불필요 (무료 체험 기본 적용).

> 두 번째 실행부터는 저장된 설정으로 바로 시작.

### Free Tier (기본)
앱을 설치하면 **API 키 없이 하루 20회 무료 대화** 가능합니다.

- 백엔드: Vercel Edge Function → Groq Llama 3.3 70B (초고속)
- 쿼터: 기기별 UTC 자정 리셋 (한국 기준 오전 9시)
- **Settings → AI Setup** 에 "Today: X / 20 free" 진행 바로 잔여량 확인

무료 한도를 초과하거나 무제한으로 쓰고 싶으면 본인 API 키 등록:

### API Key Setup (선택, 무제한)
**Settings → AI Setup → Provider** 에서 프로바이더 선택 후 API key 입력:

- **Free (no key)** — 기본값. 하루 20회 제공자 쿼터 사용
- **Gemini**: 무료 aistudio.google.com/apikey (1,500 req/day)
- **Groq**: 무료 console.groq.com/keys (14,400 req/day, 초고속)
- **Claude**: 유료 console.anthropic.com (최고 품질)
- **OpenAI**: 유료 platform.openai.com

본인 키 등록 시:
- **무제한 사용** (제공자 쿼터 내)
- **앱 → 제공자 직접 호출** (Vercel 프록시 미경유)
- 입력란 위 sage 배경의 **"Get free key at {url}"** 버튼으로 발급 페이지 열림
- 키 사이드의 👁 아이콘으로 표시/숨김 토글

### Supported Languages (9)
English (US), English (UK), Chinese (Mandarin), Chinese (Cantonese), Korean, Japanese, Spanish, French, Italian

> 모국어와 대상 언어는 같을 수 없음.

### Start Chatting
- 하단 입력바에 대상 언어로 메시지 입력
- 또는 오른쪽 **sage 원형 마이크 버튼** 을 탭해서 음성 입력
- 텍스트 입력 중엔 마이크 → Send 아이콘으로 자동 전환

---

## Chat Screen Layout (채팅 화면 구성)

| 영역 | 구성 | 기능 |
|------|------|------|
| **상단 헤더** | Alex 페블 (38px, listening) + 상태 점 + 이름 "Alex" + "Day N · Lv.X" | 브랜드 + 현재 학습 상태 |
| | 불꽃 StreakChip | 연속 학습 일수 |
| | 튠 아이콘 | Settings 화면 이동 |
| **Mission Strip** (메시지 있을 때) | target 아이콘 + 진행 라벨 + sage XP bar + trailing 라벨 | 오늘 목표 또는 활성 미션 진행률 (탭 → 미션 목록) |
| **시간 구분선** | "Today · 8:14 AM" (uppercase tiny) | 날짜 경계 |
| **메시지 리스트** | Alex 28px 페블 + 말풍선 (좌) / 사용자 sage 말풍선 (우) | 대화 내역 |
| | **Learning Drawer** (최근 AI 메시지 자동 펼침) | 번역 / 교정 / 3개 액션 버튼 |
| **Suggestion Pills** | "Try saying…" + 가로 스크롤 알약들 | 제안 문장 |
| **Composer** | + 버튼 (주제 선택) + 입력 필드 + sage 마이크/send 버튼 | 메시지 입력 |
| **배너 광고** | AdMob 배너 | - |

활성 주제 있을 때 헤더의 이름 영역에 주황색으로 주제명 + X 표시됨.

---

## Main Features

### Learning Drawer (NEW — 학습 드로어)
AI 메시지 아래에 펼쳐지는 학습 패널. 번역, 문법 교정, 3개 액션 버튼이 한 곳에 모여 있습니다.

- **기본 동작**: 가장 최근 AI 메시지의 드로어만 자동 펼침. 이전 메시지는 닫힘 상태.
- **토글**: 메시지 버블을 탭하면 드로어 열림/닫힘
- **내용**:
  - 📖 **번역** — native 언어 힌트 (translate 아이콘)
  - ✨ **교정** — 사용자의 문법 오류 ("You said X → try Y" + sparkle 아이콘)
  - **Hear it** — 문장을 TTS로 재생
  - **Try** — 따라 말하기 (발음 연습 바텀시트)
  - **Save** — 단어장 저장

### Natural Conversation
- Alex가 친근한 native speaker처럼 대화 (교과서 X)
- 문법 오류는 자연스러운 다시 말하기로 교정 + Learning Drawer에 명시적 교정 표시
- 레벨(1-10)에 따라 난이도 자동 조정

### Level System (1-10)
Settings → Learning → Level 슬라이더에서 조정. 어휘 난이도와 응답 길이 제어.

| Level | Name | Response Length | Vocabulary |
|-------|------|----------------|------------|
| 1 | Absolute Beginner | 1 sentence | Basic words (hi, yes, good) |
| 2 | Beginner | 1-2 sentences | Everyday words |
| 3 | Elementary | 2 sentences | Simple phrases |
| 4 | Pre-Intermediate | 2-3 sentences | Common idioms |
| 5 | Intermediate | 2-3 sentences | Natural conversation |
| 6 | Upper Intermediate | 3-4 sentences | Idioms & phrasal verbs |
| 7 | Pre-Advanced | 3-4 sentences | Rich vocabulary |
| 8 | Advanced | 4-5 sentences | Advanced expressions |
| 9 | Upper Advanced | 4-5 sentences | Near-native nuance |
| 10 | Native-like | ~5 sentences | Full native level |

대화 중에도 자동 보정됨 (5 메시지마다 평가).

### Conversation Suggestions
- AI 응답 후 하단에 **"Try saying…"** 라벨과 **가로 스크롤 알약 칩** 표시
- 첫 번째 칩에 머스타드 sparkle 아이콘 강조
- 각 칩: target 언어 텍스트 + (설정 시) native 힌트
- 탭하면 즉시 전송
- 모드: Immediate (즉시 표시) 또는 Delayed (1-15초 지연)

### Voice (TTS)
- AI 응답을 대상 언어로 자동 재생
- Learning Drawer의 **Hear it** 버튼으로 재생
- 조정: 음성 성별 (Female/Male), 속도 (Slow/Normal/Fast)

### Speech Input (STT)
- 입력바 오른쪽 **sage 원형 마이크** 탭 → 말하기 (활성 시 coral/stop 아이콘으로 전환)
- 실시간 부분 인식 결과가 입력바 상단에 sage-wash 영역으로 표시
- 최종 결과는 자동 전송 (옵션으로 끄기 가능)

#### Mic Pause Tolerance (NEW)
말하는 도중 생각할 시간을 주는 침묵 허용 설정. Settings → Voice → **Mic pause tolerance**:
- **Quick 3s** — 빠른 인식 (유창한 사용자)
- **Normal 5s** (기본) — 1~2초 생각 가능
- **Patient 8s** — 충분한 사고 시간 (초보자 권장)

#### Auto-Send Voice (NEW)
Settings → Voice → **Auto-send voice**:
- **ON** (기본): 인식 끝나면 즉시 전송
- **OFF**: 인식된 텍스트가 입력창에 채워짐 → 확인 후 send 버튼 직접 탭 (편집도 가능)

---

## Daily Streak (연속 학습)

매일 꾸준히 학습하는 습관을 만들어 줍니다.

- **헤더 StreakChip**: 머스타드 배경 pill에 불꽃 + 연속 일수
- **Mission Strip의 진행률**: 미션이 활성 아닐 때 "Today's goal · N of 5" + sage XP bar + "+N to go"
- **일일 목표**: 5개 메시지 전송 시 달성
- **축하**: 목표 달성 순간 머스타드 톤 SnackBar
- **리셋**: 하루 미달성 시 연속 일수 0으로

---

## Topic System (주제 시스템)

### 주제 선택
1. 채팅 입력바 **왼쪽의 + 버튼** (beige 원형) 을 탭
2. 바텀시트에서 카테고리별 주제 선택:
   - Daily Life, Travel, Food & Dining, Work & Business
   - Shopping, Health, Social, Entertainment
3. 상단에 **Today's Topic** (오늘의 추천 주제) 표시

### 주제 집중 모드 (Topic Focus Mode)
- 주제 선택 시 Alex가 해당 상황의 역할을 맡음
- 예: "Hotel Check-in" 선택 시 Alex가 호텔 리셉셔니스트 역할
- 활성 시 **헤더의 이름 자리가 주황색 주제명 + X 버튼** 으로 전환
- X 탭하면 주제 종료 → Free Talk 모드 복귀
- 대화 턴 수 자동 기록 → Weekly Report에 반영

---

## Role Play Missions (역할극 미션)

게임처럼 미션을 클리어하며 학습.

### 미션 목록 열기
- 채팅 리스트 상단 **Mission Strip** (sage-wash 카드) 을 탭 → 미션 목록 바텀시트

### 난이도
| 난이도 | 필요 턴 수 | 획득 별 | 예시 |
|--------|-----------|---------|------|
| Easy | 4턴 | 1개 | Coffee Run, Friendly Neighbor, Catch a Ride |
| Medium | 6턴 | 2개 | Fine Dining, Doctor Visit, Hotel Complaint |
| Hard | 8턴 | 3개 | Dream Job (면접), Deal Maker (협상), Friendly Debate |

### 진행 방법
1. 미션 선택 → 자동으로 Topic Focus Mode 활성화
2. 해당 상황에서 필요한 턴 수만큼 대화
3. **Mission Strip의 XP bar** 가 실시간으로 채워짐
4. 완료 시 축하 SnackBar + 별 획득
5. 완료된 미션은 체크 표시로 기록

---

## My Vocabulary (단어장)

대화 중 배운 표현을 저장하고 복습합니다.

### 단어 저장 방법
1. **채팅 메시지를 길게 누르기** → 저장 다이얼로그
2. 또는 Learning Drawer의 **Save** 버튼 → 바로 저장 다이얼로그
3. 또는 **Settings → Learning → Vocabulary → +** 버튼으로 직접 추가

### 복습 (Spaced Repetition)
- **Review** 탭에서 복습 단어 카드 표시
- 카드 탭 → 뜻 공개
- **Got it**: 정답 → 간격 증가 (1일 → 2일 → 4일 → 7일 → 14일 → 30일)
- **Again**: 오답 → 간격 1일로 리셋
- 없으면 "All caught up!"

### 단어 삭제
- All 탭에서 단어를 왼쪽으로 스와이프

---

## Weekly Report (주간 리포트)

**Settings → Learning → Weekly report** 에서 확인.

### 요약 카드
- **Messages**: 이번 주 총 메시지 수
- **Active Days**: 목표 달성 일수 (7일 중)
- **Streak**: 현재 연속 학습 일수

### Daily Activity 차트
- 최근 7일 막대 차트. 목표 달성일은 머스타드 톤, 미달성은 sage.

### Topics Practiced
- 이번 주 연습한 주제별 턴 수 (가로 막대)

### Level Changes
- 이번 주 레벨 변동 이력 + AI 평가 사유

---

## Daily Reminder (학습 알림)

매일 설정한 시간에 푸시 알림.

### 설정 방법
1. **Settings → App → Daily reminder** 스위치 ON
2. **Reminder time** 행을 탭 → 시간 설정 (기본: 20:00)
3. 앱 꺼져 있어도 알림 발송

---

## Grammar Correction (문법 교정)

대화 중 문법 오류를 자동 교정.

- AI 응답의 **Learning Drawer 내 교정 섹션** 에 표시됨 (이전: 말풍선 내 인라인 박스)
- 형식: ✨ You said ~~wrong~~ → **right** (설명)
- 응답당 최대 2개 교정
- 오류가 없으면 교정 섹션 미표시
- AI가 자연스럽게 올바른 표현으로 바꿔 말해주면서 동시에 명시적 교정도 제공

---

## Pronunciation Practice (발음 연습)

AI 메시지 문장을 따라 읽으며 발음 연습.

### 사용 방법
1. AI 메시지의 **Learning Drawer → Try 버튼** 탭
2. "Repeat After Me" 바텀시트 표시
3. **Listen first** — 원문 TTS 재생
4. **마이크 버튼** → 따라 읽기 → 다시 탭하여 중지
5. AI가 원문과 STT 결과 비교 분석
6. 점수 (1-100) + 세부 피드백

### 점수 기준
| 점수 | 등급 |
|------|------|
| 90-100 | Excellent — 거의 완벽 |
| 70-89 | Good — 약간의 개선 |
| 50-69 | Keep practicing |
| 50 미만 | Needs work |

### 한국어 화자 특화
- L/R · F/P · V/B · TH(θ/ð) 혼동
- 강세와 억양
- 연음 (gonna, wanna, I'd)

---

## Alex Avatar (페블 마스코트)

v2.3부터 Alex는 추상 페블(pebble) 마스코트로 표현됩니다. 성별 중립 디자인.

- **사이즈**: 헤더 38px / 메시지 28px / Welcome & Onboarding 72-120px
- **감정 4종** (자동 변화):
  - **calm** — 기본 대화 중
  - **listening** — 헤더에서 항상 + 웰컴 상태
  - **thinking** — 온보딩 Language Setup 페이지
  - **celebrate** — 온보딩 Welcome, Profile HeroCard
- **구성**: sage 그라디언트 몸체 + 부드러운 하이라이트 + 머스타드 볼터치 + 감정별 데코(celebrate 별, thinking 점 등)

> Settings → Voice → **Show avatar** 는 현재 추가 강조용 (기본 OFF). 헤더의 작은 Alex는 항상 표시됨.

---

## Display & Audio Options

Settings → **Conversation** 그룹:

| Option | Default | Description |
|--------|---------|-------------|
| Show {target} text | ON | AI 응답 텍스트 표시. OFF = "Tap to reveal" (리스닝 연습 모드) |
| Show {native} translation | ON | Learning Drawer의 번역 표시 ON/OFF |

Settings → **Voice** 그룹:

| Option | Default | Description |
|--------|---------|-------------|
| Read {target} aloud | ON | TTS 재생 ON/OFF |
| Read translation aloud | OFF | TTS에 native 번역 포함 여부 |
| Voice gender | Female | Female / Male |
| Speed | Normal | Slow / Normal / Fast |
| Show avatar | OFF | 대화 중 추가 아바타 강조 (헤더 Alex는 별개로 항상 표시) |

---

## Profile (설정 화면)

v2.3부터 "Settings" → **"Profile"** 로 개편.

### HeroCard
- **레벨 아바타**: 큰 sage 그라디언트 원에 현재 레벨 숫자
- **Alex celebrate**: 오른쪽 하단에 겹쳐서 표시
- **"Level N Learner"** + 레벨명 + sage XP bar
- **3개 스탯 pill**: Streak (days) / Words (saved) / Today (msgs/goal)

### 5개 그룹

**Learning**
- Vocabulary → 단어장 화면
- Weekly report → 주간 리포트 화면
- Level → 인라인 슬라이더 (1-10)
- Native language / Target language → 바텀시트 픽커

**AI Setup**
- Provider → 5종 바텀시트 (Free / Gemini / Groq / Claude / OpenAI + 설명)
- Model → 프로바이더별 모델 바텀시트
- API key → sage "Get free key at {url}" 링크 + 입력 필드 (Free 선택 시 대신 오늘 사용량 진행 바 표시)

**Conversation**
- Show target text / Show translation 스위치
- Suggestion timing (Immediate / Delayed + 슬라이더)

**Voice**
- Read aloud 스위치 (target / translation)
- Voice gender / Speed
- Mic pause tolerance (Quick 3s / Normal 5s / Patient 8s) — NEW
- Auto-send voice 스위치 — NEW

**App**
- Daily reminder + 시간
- Send feedback (이메일)

---

## Usage Tips

- **Beginner (Lv.1-3)**: native 번역 ON, TTS 속도 Slow
- **Intermediate (Lv.4-6)**: native 번역 OFF, suggestion을 힌트로 활용
- **Advanced (Lv.7-10)**: 복잡한 주제 도전, "Tap to reveal" 모드로 리스닝 연습
- **매일 습관**: Daily reminder 설정, Mission Strip 진행률 체크
- **집중 연습**: Topic Focus Mode (+ 버튼) 또는 Missions (Mission Strip)
- **단어장**: 유용한 표현을 Learning Drawer의 Save 또는 길게 눌러 저장, 매일 복습

---

## Troubleshooting

| Symptom | Solution |
|---------|----------|
| 흰 화면/스피너 멈춤 | 보안 저장소 손상 자동 복구. API 키는 재입력 필요. 여전히 멈추면 "Continue anyway" 버튼으로 진행 |
| Free tier 한도 소진 | UTC 자정 (한국 오전 9시) 이후 리셋, 또는 Settings → AI Setup 에서 본인 API 키 등록 |
| 429 error (rate limit) | 대기 후 재시도. 서버가 자동 재시도 내장 |
| "API Key Required" 카드 | 직접 Provider를 Gemini/Groq로 바꾼 경우 발생. Settings → AI Setup → Provider를 **Free (no key)** 로 되돌리거나 키 입력 |
| Invalid API key error | Settings → AI Setup 에서 키 재확인 |
| Suggestions 안 보임 | AI 응답 완료까지 대기 |
| 문법 교정 안 보임 | 사용자가 실제 오류를 낼 때만 표시. Learning Drawer 를 열어봤는지 확인 |
| 마이크가 중간에 끊김 | Settings → Voice → Mic pause tolerance 를 Patient 8s 로 변경 |
| 자동 전송이 빨라 말이 잘림 | Settings → Voice → Auto-send voice OFF → 수동 확인 후 전송 |
| Pronunciation 마이크 안 됨 | 마이크 권한 확인. STT 초기화 확인 |
| Pronunciation 점수가 이상 | STT가 발음을 자동 교정할 수 있음 (알려진 한계) |
| 소리 안 남 | 기기 볼륨 + Voice → Read aloud 확인 |
| 번역 안 보임 | Conversation → Show translation 확인 |
| AI가 native 언어 읽음 | Voice → Read translation aloud OFF (기본) |
| UI 언어가 예상과 다름 | Settings → Learning → Native language 변경 (한국어 선택 시 UI 한글, 그 외 영어) |
| 알림 안 옴 | 기기 알림 권한 확인 |
| Streak 리셋됨 | 하루 목표 미달성 시 자동 리셋 |

---

## Build & Run (Developers)

### Requirements
- Flutter SDK 3.x+ (개발 기준 3.41.5)
- Android SDK (API 21+)
- Android device with USB debugging or emulator
- (선택) Pretendard 폰트 — `assets/fonts/README.md` 참조. 미설치 시 시스템 폰트 fallback.

### Commands
```bash
# Install dependencies
flutter pub get

# Code generation (after DB or model changes)
dart run build_runner build --delete-conflicting-outputs

# Debug mode
flutter run

# Release mode (USB device)
flutter run --release

# Build APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build AAB (for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Design Tokens
Modern Sage 테마는 `lib/core/theme/` 에 토큰화되어 있음:
- `app_colors.dart` — KFPalette (light/dark)
- `app_typography.dart` — Pretendard 기반 스케일
- `app_radii.dart` / `app_spacing.dart` / `app_shadows.dart`
- `app_theme.dart` — Material 3 ThemeData 조립

### Note
- Samsung Galaxy 디바이스: **Auto Blocker** 를 꺼야 USB 디버깅 가능
  - Settings > Security and privacy > Auto Blocker > OFF
- 디버그 모드에서 첫 실행 시 `flutter_secure_storage` 복호화 실패가 나면 앱이 자동으로 저장소를 비움 (API 키만 재입력 필요)
