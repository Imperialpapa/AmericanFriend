# Language Friend - User Manual

AI tutor Alex와 자연스러운 대화를 통해 외국어를 배우는 앱입니다.
9개 언어를 지원하며, 모국어와 대상 언어를 자유롭게 선택할 수 있습니다.

---

## Getting Started

### First Launch (Onboarding)
1. **Welcome** — Meet Alex, your AI language tutor
2. **Language Setup** — Your native language is auto-detected from your device settings. Confirm or change it, then choose the language you want to learn.
3. **API Key** — Link to Settings where you can enter your AI API key
4. **Level Selection** — Choose your approximate level (1-10). It adjusts automatically as you chat.

> On subsequent launches, your saved settings are used — no setup needed.

### API Key Setup
In Settings, select an AI Model and enter the API key:
- **Gemini**: Free at aistudio.google.com/apikey (1,500 req/day)
- **Groq**: Free at console.groq.com/keys (14,400 req/day, ultra fast)
- **Claude**: Paid at console.anthropic.com (highest quality)
- **OpenAI**: Paid at platform.openai.com/api-keys

### Supported Languages (9)
English (US), English (UK), Chinese (Mandarin), Chinese (Cantonese), Korean, Japanese, Spanish, French, Italian

> Native and target language cannot be the same.

### Start Chatting
- Type a message in the target language at the bottom input bar
- Or tap the microphone button to speak

---

## Main Features

### Natural Conversation
- Alex talks like a friendly native speaker, not a textbook
- Grammar mistakes are naturally corrected through rephrasing
- Difficulty adjusts to your level (1-10)

### Level System (1-10)
Adjustable in Settings. Controls vocabulary difficulty and response length.

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

The level also auto-adjusts based on your conversation (every 5 messages).

### Native Language Translation
- AI responses include (native translation) in parentheses
- Target language text is white, translations are shown in grey
- Controllable in Settings (see Display Options below)

### Conversation Suggestions
- After AI responds, suggestion chips appear: "Try saying..."
- Target language text in yellow, native hints in blue
- Tap a suggestion to send it immediately
- Tap the speaker icon on a suggestion to hear its pronunciation
- Mode: Immediate (instant) or Delayed (1-15 seconds)

### Voice (TTS)
- AI responses are automatically read aloud in the target language
- Tap the speaker button on any AI message to replay
- Adjustable: voice gender (Female/Male) and speed (Slow/Normal/Fast)

### Speech Input (STT)
- Tap the microphone button to speak in the target language
- Real-time partial recognition shown while speaking
- Final result is automatically sent as a message

---

## Daily Streak

매일 꾸준히 학습하는 습관을 만들어 줍니다.

- **AppBar 배지**: 불꽃 아이콘 + 연속 일수 + 오늘의 진행률 (원형 프로그레스)
- **일일 목표**: 5개 메시지 전송 시 달성
- **달성 축하**: 목표 달성 시 SnackBar 축하 메시지 표시
- **streak 리셋**: 하루라도 목표 미달성 시 연속 일수가 0으로 리셋

---

## Topic System (주제 시스템)

### 주제 선택
1. AppBar의 **주제 아이콘** (Topic) 을 탭
2. 바텀시트에서 카테고리별 주제 선택:
   - Daily Life, Travel, Food & Dining, Work & Business
   - Shopping, Health, Social, Entertainment
3. 상단에 **Today's Topic** (오늘의 추천 주제) 표시

### 주제 집중 모드 (Topic Focus Mode)
- 주제를 선택하면 Alex가 해당 상황의 역할을 맡아 대화
- 예: "Hotel Check-in" 선택 시 Alex가 호텔 리셉셔니스트 역할
- AppBar에 현재 주제 이름이 주황색으로 표시
- X 버튼을 눌러 주제 종료 → Free Talk 모드로 복귀
- 대화 턴 수가 자동으로 기록됨 (Weekly Report에 반영)

---

## Role Play Missions (역할극 미션)

게임처럼 미션을 클리어하며 학습합니다.

### 미션 목록 열기
- AppBar의 **트로피 아이콘** 을 탭

### 난이도
| 난이도 | 필요 턴 수 | 획득 별 | 예시 |
|--------|-----------|---------|------|
| Easy | 4턴 | 1개 | Coffee Run, Friendly Neighbor, Catch a Ride |
| Medium | 6턴 | 2개 | Fine Dining, Doctor Visit, Hotel Complaint |
| Hard | 8턴 | 3개 | Dream Job (면접), Deal Maker (협상), Friendly Debate |

### 진행 방법
1. 미션 선택 → 자동으로 Topic Focus Mode 활성화
2. 해당 상황에서 필요한 턴 수만큼 대화
3. 완료 시 축하 SnackBar + 별 획득
4. 완료된 미션은 체크 표시로 기록

---

## My Vocabulary (단어장)

대화 중 배운 표현을 저장하고 복습합니다.

### 단어 저장 방법
1. **채팅 메시지를 길게 누르기** → 저장 다이얼로그 표시
2. 표현을 편집한 뒤 Save
3. 또는 Settings > **My Vocabulary** > **+** 버튼으로 직접 추가

### 복습 (Spaced Repetition)
- **Review** 탭에서 복습할 단어 카드 표시
- 카드를 탭하면 뜻 공개
- **Got it**: 정답 → 복습 간격 증가 (1일 → 2일 → 4일 → 7일 → 14일 → 30일)
- **Again**: 오답 → 간격이 1일로 리셋
- 복습할 단어가 없으면 "All caught up!" 표시

### 단어 삭제
- All 탭에서 단어를 왼쪽으로 스와이프하여 삭제

---

## Weekly Report (주간 리포트)

Settings > **Weekly Report** 에서 확인할 수 있습니다.

### 요약 카드
- **Messages**: 이번 주 총 메시지 수
- **Active Days**: 목표 달성 일수 (7일 중)
- **Streak**: 현재 연속 학습 일수

### Daily Activity 차트
- 최근 7일간 일별 메시지 수 막대 차트
- 목표 달성일은 주황색, 미달성은 기본 색상

### Topics Practiced
- 이번 주 연습한 주제별 턴 수 (가로 막대)
- 주제 집중 모드 사용 시 자동 기록

### Level Changes
- 이번 주 레벨 변동 이력과 AI의 평가 사유

---

## Daily Reminder (학습 알림)

매일 설정한 시간에 학습 리마인더 알림을 받습니다.

### 설정 방법
1. Settings > **Daily Reminder** 섹션
2. **Enable reminder** 스위치 ON
3. **Reminder time** 탭하여 시간 설정 (기본: 20:00)
4. 앱이 꺼져 있어도 알림이 발송됨

---

## Display & Audio Options

### Target Language
| Option | Default | Description |
|--------|---------|-------------|
| Show text | ON | Display AI response text on screen. OFF = "Tap to reveal" mode (listening practice) |
| Read aloud | ON | TTS playback. Turn OFF in quiet environments |

### Native Language
| Option | Default | Description |
|--------|---------|-------------|
| Show translation | ON | Show (native) translation hints in responses. OFF = target language only |
| Read translation aloud | OFF | Include native translations in TTS playback |

---

## Settings Reference

| Section | Item | Description |
|---------|------|-------------|
| **Weekly Report** | Report card | View weekly learning statistics |
| **My Vocabulary** | Vocabulary card | View saved words & review flashcards |
| **Language** | Native Language | Your mother tongue (default: Korean) |
| | Target Language | The language you're learning (default: English US) |
| **Level** | Level slider (1-10) | Controls AI response difficulty and length |
| **AI Model** | Provider | Gemini, Groq, Claude, OpenAI |
| | Model Version | Per-provider model selection (e.g., Gemini 2.5 Flash/Pro) |
| **API Key** | Key input | API key for the selected model |
| **Target Language** | Show text | Display AI response text ON/OFF |
| | Read aloud | TTS for target language ON/OFF |
| **Native Language** | Show translation | Display native hints ON/OFF |
| | Read translation aloud | TTS for native language ON/OFF |
| **Suggestions** | Mode | Immediate or Delayed (1-15s) |
| **Voice** | Gender | Female / Male |
| | Speed | Slow / Normal / Fast |
| **Daily Reminder** | Enable reminder | Push notification ON/OFF |
| | Reminder time | Notification time (default: 20:00) |
| **Feedback** | Send Feedback | Email improvement suggestions to developer |

### AI Model + Language Compatibility
- Gemini, Claude, OpenAI: All 9 languages fully supported
- Groq (Llama 3.3): Warning shown for Cantonese, Mandarin, Italian (quality may be lower)

---

## AppBar Quick Guide

채팅 화면 상단 AppBar의 아이콘 설명:

| 위치 | 아이콘 | 기능 |
|------|--------|------|
| 왼쪽 | A (아바타) + 레벨 | Alex 프로필, 현재 레벨 표시 |
| 왼쪽 | 주제명 (주황색) | 활성 주제 표시 (X로 종료) |
| 오른쪽 | 불꽃 + 숫자 | Daily Streak 배지 |
| 오른쪽 | Topic 아이콘 | 주제 선택 바텀시트 |
| 오른쪽 | 트로피 아이콘 | 미션 목록 바텀시트 |
| 오른쪽 | 설정 아이콘 | Settings 화면 |

---

## Usage Tips

- **Beginner (Lv.1-3)**: Enable native translations, set speech speed to Slow
- **Intermediate (Lv.4-6)**: Disable native translations, use suggestions as hints
- **Advanced (Lv.7-10)**: Try complex topics, use "Tap to reveal" mode for listening practice
- **Daily habit**: Set a reminder, aim for the daily streak goal
- **Focused practice**: Use Topic Focus Mode or Missions for specific scenarios
- **Vocabulary building**: Long-press useful expressions in chat to save, review daily

---

## Troubleshooting

| Symptom | Solution |
|---------|----------|
| 429 error (rate limit) | Wait and retry. Auto-retry (2-8s backoff) is built in |
| Invalid API key error | Check your key in Settings |
| Suggestions not showing | Wait for AI response to complete |
| No audio | Check device volume, verify "Read aloud" is ON in Settings |
| Native language not shown | Verify "Show translation" is ON in Settings |
| AI reads native language | Ensure "Read translation aloud" is OFF (default) |
| Notification not received | Check device notification permissions for the app |
| Streak reset unexpectedly | Streak resets if daily goal is not met for a day |

---

## Build & Run (Developers)

### Requirements
- Flutter SDK 3.x+
- Android SDK (API 21+)
- Android device with USB debugging or emulator

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
```

### Note
- Samsung Galaxy devices: Disable **Auto Blocker** for USB debugging
  - Settings > Security and privacy > Auto Blocker > OFF
