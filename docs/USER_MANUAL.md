# American Friend - 사용자 매뉴얼

AI 친구 Alex와 영어로 자연스럽게 대화하며 실력을 키우는 앱입니다.

---

## 시작하기

### 1. API 키 설정
1. 앱 실행 후 우측 상단 **Settings(톱니바퀴)** 아이콘 탭
2. AI Model에서 원하는 모델 선택 (기본: Google Gemini)
3. 해당 모델의 API Key 입력
   - **Gemini**: https://aistudio.google.com/apikey 에서 무료 발급
   - **Groq**: https://console.groq.com/keys 에서 무료 발급
   - **Claude**: https://console.anthropic.com 에서 발급 (유료)
   - **OpenAI**: https://platform.openai.com/api-keys 에서 발급 (유료)

### 2. 대화 시작
- 화면 하단 입력창에 영어로 메시지를 입력하면 Alex가 답변합니다
- 마이크 버튼을 눌러 음성으로 대화할 수도 있습니다

---

## 주요 기능

### 자연스러운 영어 대화
- Alex는 미국인 친구처럼 자연스러운 영어로 대화합니다
- 문법 실수를 자연스럽게 교정해 줍니다
- 사용자 레벨(1~10)에 맞춰 난이도를 조절합니다

### 한글 번역 표시
- AI 응답에 영어 문장과 함께 (한국어 번역)이 표시됩니다
- 영어는 흰색, 한글 번역은 회색으로 구분됩니다
- Settings에서 **한글 번역 표시**를 끌 수 있습니다

### 대화 제안 (Suggestion)
- AI 응답 후 "이렇게 말해 볼까요?" 제안 문장이 표시됩니다
- 제안문: 영어는 노란색 대괄호 `[...]`, 한글은 파란색 괄호 `(...)`
- 제안을 탭하면 바로 해당 문장으로 대화가 이어집니다
- Settings에서 즉시/지연 모드를 선택할 수 있습니다

### 음성 기능 (TTS)
- AI 응답이 도착하면 자동으로 영어 발음을 읽어줍니다 (한글 제외)
- 각 AI 메시지 우측 하단의 **스피커 버튼**을 탭하면 다시 들을 수 있습니다
- Settings에서 조절 가능:
  - **목소리 성별**: 여성 / 남성
  - **말하기 속도**: Slow ~ Fast

### 음성 입력 (STT)
- 하단의 마이크 버튼을 눌러 영어로 말하면 텍스트로 변환되어 전송됩니다

---

## Settings 설명

| 항목 | 설명 |
|------|------|
| AI Model | 사용할 AI 모델 선택 (Gemini, Groq, Claude, OpenAI) |
| API Key | 선택한 모델의 API 키 입력 |
| Conversation Suggestions | 제안 표시 모드 (Immediate: 즉시 / Delayed: 지연) |
| 한글 번역 | AI 응답과 제안에 한글 번역 표시 ON/OFF |
| Voice - 성별 | TTS 목소리 여성/남성 선택 |
| Voice - Speech speed | TTS 말하기 속도 조절 |

---

## 팁

- **초급자**: 한글 번역을 켜고, 말하기 속도를 Slow로 설정하세요
- **중급자**: 한글 번역을 끄고, 제안 문장을 참고하며 직접 문장을 만들어 보세요
- **고급자**: 복잡한 주제로 대화를 시도하고, 관용표현을 배워보세요

---

## 문제 해결

| 증상 | 해결 방법 |
|------|-----------|
| 429 에러 (요청 한도 초과) | 잠시 기다린 후 재시도. 자동 재시도(2~8초) 내장됨 |
| 404 에러 | Settings에서 API 키 확인 |
| 제안 문장이 안 보임 | AI 응답을 기다린 후 확인 |
| 음성이 안 나옴 | 기기 볼륨 확인, Settings에서 속도 조절 |

---

## 빌드 & 실행 방법 (개발자용)

### 요구사항
- Flutter SDK 3.x 이상
- Android SDK (API 21+)
- USB 디버깅 가능한 Android 기기 또는 에뮬레이터

### 실행
```bash
# 의존성 설치
flutter pub get

# 디버그 모드 실행
flutter run

# 릴리즈 모드 (USB 연결된 기기)
flutter run --release

# APK 빌드
flutter build apk --release
```

### 참고
- Samsung Galaxy 기기는 **Auto Blocker**를 꺼야 USB 디버깅이 가능합니다
  - 설정 → 보안 및 개인정보 보호 → Auto Blocker → OFF
