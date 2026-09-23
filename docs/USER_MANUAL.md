# Korean Friend - User Manual

AI tutor Alex와 자연스러운 대화를 통해 외국어를 배우는 앱입니다.
9개 언어를 지원하며, 모국어와 대상 언어를 자유롭게 선택할 수 있습니다.

> **v2.5.0 업데이트 (2026-04-27)** — Play Store 릴리즈
>
> **신규 (v2.3.2 → 2.5.0 누적)**
> - **자연스러움 팁 `💬 More natural`** — 레벨 4+ 응답 끝에 더 native한 표현 1줄 (문법 교정 `💡`과 별개)
> - **두 손가락 핀치 → 메시지 폰트 즉시 조절** — 채팅 화면에서 두 손가락 모으기/벌리기, 사진 앱과 동일한 UX (0.5x ~ 2.8x)
>
> **개선 (v2.3.1)**
> - **답변 대기 시간 — Samsung OEM 우회** — STT 자체 silence 타이머로 슬라이더 값(3~15초) 그대로 보장
> - **제안 대기 시간 슬라이더 통합** — 0=즉시, 1~15초로 단순화 (이전 모드 토글 + 슬라이더 분리되어 있던 것 통합)
> - **레벨 동기화 버그 수정** — 앱 재시작 후 첫 메시지가 저장된 레벨 무시하던 문제 수정
>
> **이전 핵심 기능 (v2.3.0)**
> - **무료 체험 내장** — API 키 없이 하루 20회 무료 대화 (Vercel 프록시 + Groq)
> - **UI 한/영 자동 전환** — 모국어가 한국어면 UI도 한글, 그 외는 영어
> - **온보딩 3단계** — Welcome → Language → Level (API 키 입력 제거)
> - **Learning Drawer** — 듣기/따라하기/저장 버튼이 모든 AI 답변에서 작동
> - **사용자 메시지 발음 연습** — 본인이 보낸 메시지도 길게 눌러 연습·단어장 저장
> - **시작 오류 자동 복구** — 보안 저장소 손상 시 자동 복구
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
- **제안 대기 시간** 슬라이더 (0~15초): 0이면 AI 응답 직후 즉시 노출, 1~15초면 그 시간만큼 직접 답할 시간을 준 뒤 노출

### Voice (TTS)
- AI 응답을 대상 언어로 자동 재생
- Learning Drawer의 **Hear it** 버튼으로 재생
- 조정: 음성 성별 (Female/Male), 속도 (Slow/Normal/Fast)

### Speech Input (STT)
- 입력바 오른쪽 **sage 원형 마이크** 탭 → 말하기 (활성 시 coral/stop 아이콘으로 전환)
- 실시간 부분 인식 결과가 입력바 상단에 sage-wash 영역으로 표시
- 최종 결과는 자동 전송 (옵션으로 끄기 가능)

#### Time to Respond (답변 대기 시간)
말하는 도중 잠깐 멈춰도 AI가 답변을 가로채지 않게 하는 설정. Settings → Voice → **답변 대기 시간 / Time to respond** 슬라이더 (3~15초, 기본 5초).

> **내부 동작**: Android(특히 Samsung)는 OS 차원의 STT silence detection이 강해서 라이브러리의 `pauseFor` 인자를 무시하는 경우가 많음. 그래서 v2.3.1부터 앱이 자체 silence 타이머를 관리 — STT가 일찍 종료되어도 자동 재시작해서 사용자 발화를 끝까지 받음. 슬라이더 값만큼 진짜로 기다려준다.

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
- 제안 대기 시간 / Time before hints — 슬라이더 (0~15초, 0=즉시)

**Voice**
- Read aloud 스위치 (target / translation)
- Voice gender / Speed
- 답변 대기 시간 / Time to respond — 슬라이더 (3~15초)
- Auto-send voice 스위치

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
| 마이크가 중간에 끊김 / 답변 도중 가로채임 | Settings → Voice → **답변 대기 시간(Time to respond)** 슬라이더를 12~15초로 늘리기. v2.3.1부터 자체 silence 타이머로 OEM 무시 우회 |
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

---

## v2.3.1 변경 사항 (2026-04-26)

### 한 일 — 설정 옵션 점검 + 버그 3건 수정

이번 패치는 사용자가 보고한 "설정 옵션이 잘 작동하지 않는 것 같다"는 의심에서 출발해, 설정 화면의 모든 옵션이 실제 코드 동작과 일치하는지 전수 점검. 결과 점검 리포트는 `docs/SETTINGS_AUDIT_2026-04-26.md`.

**🔴 버그 1 — 사용자 레벨 동기화 누락**
- 증상: 앱 재시작 후 첫 메시지가 항상 레벨 5 시스템 프롬프트로 처리 (저장된 레벨 무시)
- 원인: `ChatNotifier`가 자체 `userLevel` state(default 5)를 가지고 있고, `chat_screen`의 `ref.listen(levelProvider)`은 변경 시에만 트리거됨 → 첫 진입 시 동기화 안 됨
- 수정: `ChatState.userLevel` 필드 제거, 매 메시지 전송 시 `ref.read(levelProvider).currentLevel`로 직접 조회. 두 provider 간 type-inference cycle은 명시 타입으로 해결.

**🔴 버그 2 — 제안 타이밍 옵션 완전 미작동**
- 증상: Immediate ↔ Delayed 토글, 1~15초 슬라이더 모두 효과 없음. 항상 default(delayed, 5초)로 동작.
- 원인: `SuggestionNotifier`가 자체 mode/delaySec state를 가지는데, `settingsProvider` 변경 시 동기화하는 코드가 없음. `setMode`/`setDelay` 호출처 0건.
- 수정 + 옵션 통합: 두 옵션이 사실상 같은 축이라 슬라이더 하나로 통합 (0~15초, 0=즉시). 라벨 "**제안 대기 시간 / Time before hints**". 마이그레이션: 옛 immediate 사용자 → delay=0 자동 변환.

**🟡 버그 3 — flutterTtsProvider 인스턴스 재생성**
- 증상: 모든 설정 변경 시마다 FlutterTts 새 인스턴스 생성 → TtsQueue/ConversationPipeline cascade로 재생성 → 진행 중인 TTS 끊김 가능
- 수정: `ref.watch` → `ref.read` + 3개의 `select()` 기반 `ref.listen`. 인스턴스 1개만 유지. `ref.onDispose(() => tts.stop())`.

### STT 우회 구현 — 답변 대기 시간이 진짜로 작동

**문제**: Android(특히 Samsung 등 한국 OEM)가 `SpeechRecognizer`의 `EXTRA_SPEECH_INPUT_*_SILENCE_LENGTH_MILLIS`를 자체 silence detection으로 덮어씀. 그래서 `speech_to_text` 패키지의 `pauseFor`를 8초로 줘도 2~3초만에 STT가 자체 종료되고, autoSendVoice가 켜져 있으면 즉시 send → AI가 답변을 가로채는 현상.

**우회 (`voice_provider.dart`)**: 자체 silence 타이머 도입.
1. STT final 결과를 받아도 즉시 send X → `_pendingText`에 누적
2. `sttPauseSeconds` 길이의 타이머 시작 + STT 자동 재시작
3. 추가 final 오면 텍스트 누적 + 타이머 리셋
4. 타이머 만료 → 누적 텍스트 한 번에 send
5. 사용자가 마이크 버튼 토글로 끄면 즉시 send (현행 동작 유지)

옵션 범위도 확장: SegmentedButton (3/5/8) → 슬라이더 (3~15초).

### 라벨 정리

| 옵션 | v2.3 라벨 | v2.3.1 라벨 |
|------|-----------|-------------|
| `sttPauseSeconds` | 마이크 멈춤 허용 / Mic pause tolerance | **답변 대기 시간 / Time to respond** |
| `suggestionDelaySec` | 제안 시점 / Suggestion timing | **제안 대기 시간 / Time before hints** |

> 두 옵션 모두 "사용자에게 시간을 주는" 개념이지만 작용 시점이 다름 — 답변 대기 시간은 **말하는 도중** 멈춰도 AI가 가로채지 않는 시간, 제안 대기 시간은 **AI 응답 후** 직접 답해볼 시간.

---

---

## v2.3.2 변경 사항 (2026-04-26 후속)

### Filler / Naturalness Tip 도입 (#10)

회화 능력 향상 아이디어 중 ROI 가장 높다고 본 항목 1순위 진행.

**변경:**
- `system_prompt.dart` — `_naturalnessTipRule(level)` 추가. 레벨 4+에서만 NATURALNESS TIP 블록을 시스템 프롬프트에 주입. 레벨 1-3은 기본 어휘 학습에 집중하기 위해 제외.
- AI가 응답 끝에 (있을 경우) 한 줄의 `💬 More natural: "<alternative>"` 추가
- 이 줄은 grammar correction(💡)과는 별개 — 문법은 맞지만 더 자연스럽게 말할 수 있는 경우용
- `message_bubble.dart` — `_splitCorrections`을 corrections + tips 두 그룹으로 분리. Learning Drawer에 sage 컬러 chat_bubble 아이콘으로 별도 표시
- `conversation_pipeline.dart` — TTS skip 패턴에 💬 추가 (자연스러움 팁은 음성 재생 안 함)
- 응답당 최대 1개 💬, 의미 있는 개선이 있을 때만 (강제 X)

**예시:**
- User: "Yes" → AI 응답 끝: `💬 More casual: "Yeah, totally"`
- User: "I don't know" → `💬 Native often: "I'm not too sure"`

### Pinch-to-Resize — 메시지 폰트 크기

채팅 화면에서 **두 손가락으로 모으거나 벌려서** 메시지 폰트 크기를 즉시 조절. 사진/지도 앱과 동일한 UX.

**구현:**
- `chat_screen.dart` — `RawGestureDetector` + `ScaleGestureRecognizer`. 두 손가락 이상(`pointerCount >= 2`)일 때만 활성, 한 손가락 스크롤은 그대로 ListView에 전달
- `setChatFontScale(scale, {persist: true})` — 핀치 도중엔 `persist: false`로 메모리만, 제스처 종료 시 디스크 저장
- 범위: 0.5 ~ 2.8 (clamp, 기본 1.0의 1/2 ~ 2배 이상). 사용자 메시지/AI 메시지/숨김 텍스트 본문 모두 적용. drawer 내 corrections/tips는 보조 정보라 고정 크기 유지
- `user_settings.dart` — `chatFontScale: double` (default 1.0) 영구 저장

설정 화면에 별도 옵션은 두지 않음 — 핀치만으로 충분히 직관적이라 판단.

**다음 후보 (Phase A 남은 항목):**
- #15 실전 모드 토글
- #16 자동 단어 강조

---

## v2.5.0 릴리즈 (2026-04-27) — Play Store

### 의미
v2.3.1 안정화 + v2.3.2 신규 기능을 묶어 Play Store 정식 업로드용 릴리즈.
versionCode 24 → 25, versionName 2.3.1 → **2.5.0**.

### 포함 변경
- v2.3.1: 설정 점검 + 3건 버그 수정 (레벨 동기화 / 제안 타이밍 / TTS 인스턴스 재생성), STT silence 우회
- v2.3.2: 자연스러움 팁 (`💬 More natural`), 두 손가락 핀치 폰트 조절

### 빌드
- AAB: `build/app/outputs/bundle/release/app-release.aab` (51 MB)
- 서명: release keystore (key.properties)
- minSdk / targetSdk: Flutter 기본값 사용 (`android/app/build.gradle.kts`)

### 업로드 절차
1. [Play Console](https://play.google.com/console) → 앱 선택
2. **프로덕션** 또는 **테스트 트랙** → **새 버전 만들기**
3. 위 AAB 업로드 → 릴리즈 노트 작성 → 검토 → 출시

> 다음 패치 버전부터는 `pubspec.yaml`의 `version: 2.5.X+N` 형식으로 올리면 됨 (versionCode `+N`은 항상 직전보다 커야 함).

---

## 할 일 (Roadmap)

### 즉시 — 실기기 검증

- [ ] **Galaxy S26 Ultra 실기기 테스트** (사용자 진행 중)
  - 답변 대기 시간 12s로 두고 영어로 말하다 4~5초 멈춤 → AI가 가로채지 않고 끝까지 듣는지
  - STT 재시작 갭(~80ms)에서 첫 단어 누락이 있는지
  - 첫 발화 없이 마이크 토글 → 정상 idle 복귀
  - 레벨 슬라이더 변경 → 앱 재시작 → 첫 메시지가 새 레벨로 응답하는지
  - 제안 대기 시간 0초/8초로 바꿔보고 실제 노출 시점 확인

### 다음 우선순위 (메모리에 보관 중인 작업)

- [ ] **발음 평가** (Phase 1: AI 기반 → Phase 2: Azure Speech)
  - 상세: `docs/ANALYSIS_PRONUNCIATION_LEVEL.md`
- [ ] **레벨 테스트 확장** — Speaking / Listening / Grammar / Vocabulary 4영역 멀티스킬 평가
  - 상세: `docs/feature_roadmap.md`

---

## 회화 능력 향상을 위한 추가 아이디어

기존 기능(대화, 단어장, streak, mission, weekly report)과 시너지를 낼 수 있는 후보들. 우선순위 매겨놓되, 모두 구현이 아니라 **고를 후보 리스트**.

### High Impact (회화 능력 직결)

**1. Shadowing 모드** — 듣고 따라 말하기
- AI 응답 → TTS 재생 → 사용자가 같은 문장 음성 발화 → 발음/속도/억양 일치도 평가
- Pronunciation Practice의 확장 — 선택한 한 문장이 아니라 응답 전체를 따라 함
- 발음 평가 Phase 1과 자연스럽게 결합

**2. 약점 진단 → 집중 미션 자동 생성**
- Weekly Report 데이터에서 "이번 주 가장 자주 틀린 패턴"을 추출 (예: 시제 실수, a/the 누락)
- 그 패턴을 **강제로 발화하게 하는 시나리오 미션** 자동 생성
- 예: 과거 시제 실수 잦으면 → "Tell me about yesterday" 형식의 회상 미션
- 기존 mission 시스템과 그대로 통합 가능

**3. 표현(Phrase) SRS — 단어 너머**
- 현재 단어장은 단어/짧은 문장 단위. 회화는 단어보다 **chunk(in the long run, by and large, get the hang of)**가 핵심
- 메시지 길게 누를 때 "phrase로 저장" 옵션 추가, SRS 카드도 "이 표현을 새 문장에 사용해보세요" 형식
- 수동적 암기 → 능동적 사용으로

### Medium Impact (재미/지속력)

**4. 일상 시나리오 제너레이터**
- 사용자가 "Today I have a dentist appointment" 같은 한 줄 입력
- AI가 그 상황의 모의 대화 자동 구성 (역할, 예상 질문, 핵심 어휘 미리 표시)
- 미션 시스템과 통합 — 사용자 자작 미션

**5. 음성 발화 강제 모드 (Voice-Only 토글)**
- 텍스트 입력 잠금 → 음성으로만 입력
- 회피 본능을 강제로 막아 발화량 증가
- "오늘은 voice-only" 같은 daily challenge 카드로

**6. Conversation Highlights — 주간 회고 카드**
- Weekly Report에 새 섹션: 이번 주 "잘한 표현 / 새로 배운 표현 / 자주 막힌 부분"
- AI가 대화 로그에서 자동 추출
- 학습 동기 유지 (게임의 end-of-match summary 효과)

### 회화 특유 스킬 / 자가 모니터링 (책에 없는 영역)

**10. Filler / Backchanneling 코칭** ⭐
- AI 응답에 "자연스러움 팁" 한 줄 — *Native speakers might say 'uh-huh' or 'right' here*
- 사용자 응답 시 backchannel 사용 빈도 추적, weekly report에 표시
- **한국 학습자가 가장 빠르게 native-like해지는 영역**. 시스템 프롬프트 한 블록 추가로 구현 가능
- 비용 낮음 / 효과 큼 → **1순위 후보**

**11. 본인 음성 다시 듣기 (Self-listening)**
- STT 입력의 원본 오디오를 7일 보관 → "1주일 전 본인 발화" 카드
- 같은 표현을 1주 전과 오늘 어떻게 발음했는지 비교
- 자기 발음 인식 + 진전 체감
- 비용 중간 (오디오 저장 인프라 필요)

**12. 응답 다양성 코치**
- 반복 패턴 감지: "이번 주 'I think' 23번 사용 → 'In my view / I'd say' 시도해볼래요?"
- weekly report에 "다양성 점수" 카드 추가
- 자동화된 데이터 기반, 사용자 노력 0
- 비용 작음 (DB 쿼리 + 분석)

**13. 1분 Monologue Challenge**
- 매일 한 번 "Speak about your weekend for 1 minute non-stop"
- 측정: 분당 단어 수, hesitation(uh, um) 비율, 사용 어휘 폭
- **발화 지속력**은 회화 자신감의 기반인데 단답 대화로는 안 길러짐
- 비용 중간 (별도 화면 + 분석 로직)

**14. Paraphrase 챌린지 (어휘 부족 우회)**
- "Explain *'procrastinate'* without using the word itself"
- 모르는 단어 마주쳤을 때 풀어서 설명하는 능력 — 회화에서 막히지 않게 하는 핵심 기술
- 미션 시스템에 한 카테고리로 통합
- 비용 작음

**15. 실전 모드 토글**
- 평소 모드: 교정/번역/제안 모두 ON (학습용)
- 실전 모드: native speaker처럼만 — 자신감 측정용
- 일주일에 한 번 자동 권유 → 결과를 weekly report에 기록 ("실전 점수")
- 비용 작음 (시스템 프롬프트 분기 + 토글 UI)

### Polish / Experimental

**16. 레벨에 맞춘 자동 단어 강조**
- AI 응답에서 사용자 레벨 대비 **어려운 단어만** 자동 강조 + 인라인 번역
- 현재 showNativeHint는 전체 ON/OFF — 한 단계 더 정교하게
- 본문 가독성을 해치지 않으면서 학습 효과↑

**17. Listening test (받아쓰기 모드)**
- AI가 음성으로만 한 문장 발화 (텍스트 숨김) → 사용자가 받아쓰기
- 듣기 능력 단독 훈련. 현재는 "Tap to reveal"로 비슷한 효과를 내지만 정식 모드화

**18. 장기 목표 → 자동 주간 미션**
- 온보딩에 "Why are you learning English?" 한 줄 입력 받기 (예: "I want to give a presentation in 3 months")
- AI가 그 목표 기반으로 **매주 미션 셋트 자동 생성**
- 학습이 일회성 대화가 아니라 목표 지향 여정이 됨

### 추천 진행 순서 (ROI 기준)

**Phase A — 시스템 프롬프트만으로 가능 (즉시):**
1. **#10 Filler/Backchanneling 코칭** — 시스템 프롬프트 한 블록 추가, 가장 빠른 자연스러움 향상
2. **#15 실전 모드 토글** — 시스템 프롬프트 분기 + 설정 토글
3. **#16 자동 단어 강조** — 시스템 프롬프트 + 인라인 표시 살짝 수정

**Phase B — UI/로직 추가 (중기):**
4. **#5 Voice-Only 토글** — 입력바에 토글 한 개
5. **#12 응답 다양성 코치** — DB 쿼리 + weekly report 카드 추가
6. **#14 Paraphrase 챌린지** — mission 카테고리 추가

**Phase C — 별도 인프라 필요 (장기):**
7. **#1 Shadowing** — 발음 평가 Phase 1과 결합
8. **#11 본인 음성 다시 듣기** — 오디오 보관 인프라
9. **#13 1분 Monologue** — 별도 화면 + 분석
10. **#2 약점 진단 미션** — 패턴 분석 파이프라인
11. **#3 Phrase SRS** — 단어장 시스템 확장

> Phase A는 매우 빠르게 (각 1-2시간) 구현 가능. Phase B는 별도 세션 단위. Phase C는 메모리에 보관 중인 발음 평가/레벨 테스트와 함께 일정 잡아 진행.
