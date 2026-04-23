# Screen Inventory — Korean Friend (eng_friend) v2.2.0

> Claude Design 리디자인을 위한 현재 화면 구조 문서
> 작성일: 2026-04-23

## 앱 개요
- **이름**: Korean Friend (내부 패키지명: eng_friend)
- **AI 캐릭터**: Alex
- **목적**: AI 채팅 기반 외국어 학습 (한국어 사용자가 영어 등 학습)
- **플랫폼**: Flutter (Android/iOS), Material 3
- **상태관리**: Riverpod
- **타겟 디바이스**: 모바일 (Galaxy S24 Ultra 기준)

## 라우팅 구조
- 첫 진입: 온보딩 미완료 시 `OnboardingScreen` → 완료 시 `ChatScreen`
- `ChatScreen`이 메인 허브, AppBar의 아이콘으로 다른 기능 진입
- 정식 라우터(go_router) 미사용, MaterialPageRoute로 push

---

## 1. OnboardingScreen (lib/features/onboarding/presentation/screens/onboarding_screen.dart)

**역할**: 첫 사용자가 거치는 4단계 셋업

**페이지 구성**:
1. **Welcome** — Alex 캐릭터 인사 (CircleAvatar 'A' 텍스트), "Let's Go!" CTA
2. **Language Setup** — 모국어/대상 언어 드롭다운 2개
3. **API Key** — Gemini/Groq SegmentedButton 선택 → 3단계 카드 (URL 열기 → 키 생성 → 붙여넣기)
4. **Level** — 1~10 슬라이더, 레벨명 표시, "Start Chatting!"

**핵심 위젯**: `CircleAvatar`, `FilledButton`, `SegmentedButton`, `Card`, `Slider`, `DropdownButtonFormField`, `BannerAdWidget`

**문제점/개선여지**:
- CircleAvatar에 단순 "A" 텍스트만 있음 (캐릭터 일러스트 없음)
- 4페이지가 모두 같은 레이아웃 톤 (도트 인디케이터 없음 → 진행률 불명확)
- Page 2/3/4의 헤더 간격이 일관되지 않음 (`SizedBox(height: 40)` vs `24`)
- API Key 페이지가 정보 밀도 높음 (스크롤 필요)

---

## 2. ChatScreen (lib/features/chat/presentation/screens/chat_screen.dart) — **메인 화면**

**역할**: AI Alex와의 대화 + 모든 기능 진입점

**구성**:
- **AppBar**:
  - Leading: CircleAvatar 'A' + 캐릭터명 "Alex" + 레벨 표시 (Lv.X · 레벨명)
  - Topic 활성화 시 캐릭터명 대신 토픽명(주황색)
  - Actions: StreakBadge, Topic 아이콘, Mission 아이콘(트로피), Settings 아이콘
- **Body**:
  - (옵션) AvatarWidget (Lottie 애니메이션, 120x120)
  - 에러 시 MaterialBanner
  - Welcome message (대화 없을 때) — CircleAvatar 큰 'A' + 인사문 + (API key 없으면 errorContainer 카드)
  - 메시지 리스트 (`MessageBubble` + 스트리밍 + `SuggestionChips`)
- **Bottom**: `ChatInputBar` + `BannerAdWidget`

**SnackBar 알림**: streak 목표 달성 (오렌지), 미션 완료 (앰버)

**문제점/개선여지**:
- AppBar가 정보 과밀 (캐릭터/레벨/스트릭/3개 액션 버튼)
- 'A' CircleAvatar가 일러스트 없이 텍스트뿐 — 브랜드감 부족
- AvatarWidget이 본문 위에 끼어들어 메시지 영역을 침범
- 토픽 활성화 표시가 AppBar에 끼워넣어져 좁음

---

## 3. SettingsScreen (lib/features/settings/presentation/screens/settings_screen.dart)

**역할**: 모든 설정 (긴 ListView)

**섹션 순서**:
1. Weekly Report 카드 (네비게이션)
2. My Vocabulary 카드 (네비게이션)
3. Language (Native/Target 드롭다운 + 호환성 경고)
4. Level (슬라이더 + 설명)
5. AI Model (RadioListTile 4종 — Gemini/Groq/Claude/OpenAI)
6. Model Version (선택된 프로바이더의 모델 RadioListTile)
7. API Key (선택된 프로바이더만 입력)
8. Conversation Suggestions (Immediate/Delayed SegmentedButton + 슬라이더)
9. Target Language Options (Show text / Read aloud SwitchListTile)
10. Native Language Options (Show translation / Read translation SwitchListTile)
11. Voice (Female/Male SegmentedButton + 속도 슬라이더)
12. Avatar (Show avatar SwitchListTile)
13. Daily Reminder (활성/시간 선택)
14. Feedback (이메일 보내기 카드)

**문제점/개선여지**:
- 14개 섹션이 단일 ListView에 다이브 — 검색/그루핑 없음
- 카드 디자인이 일관성 부족 (어떤 건 Card, 어떤 건 Divider만)
- 시각적 위계 약함 (모든 titleMedium이 같은 두께)
- Weekly Report / Vocabulary가 설정 안에 묻혀 있음 — 별도 Tab/Drawer로 빼는 게 더 자연스러울 수 있음

---

## 4. VocabularyScreen (lib/features/vocabulary/presentation/screens/vocabulary_screen.dart)

**역할**: 저장한 단어/표현 관리 + 간격반복 복습

**구성**: TabBar 2개
- **All**: ListView + Dismissible (스와이프 삭제) — 표현/뜻/상태 인디케이터(점)/주기일
- **Review**: 카드 탭으로 뜻 공개 → "Again"/"Got it" FilledButton (빨강/초록)

**FAB**: 단어 추가 다이얼로그

**문제점/개선여지**:
- 상태 점(빨강/주황/초록)이 작아서 의미 전달 약함
- Review 카드가 매우 단순 (탭하면 뜻 보임) — 학습 동기 약함
- 빈 상태 ("All caught up!")는 OK, 다른 빈 상태도 일관되게 정리 필요

---

## 5. WeeklyReportScreen (lib/features/report/presentation/screens/weekly_report_screen.dart)

**역할**: 주간 학습 통계

**구성**:
- 요약 카드 (Messages / Active Days / Streak — 3컬럼)
- Daily Activity 차트 (자체 구현 막대그래프, 7일)
- Topics Practiced (LinearProgressIndicator 리스트)
- Level Changes (ListTile 리스트)

**문제점/개선여지**:
- 차트가 매우 기본적 (막대 + 숫자만) — 트렌디한 데이터 시각화 가능
- 카드 1개만 있고 나머지는 plain section — 일관성 부족

---

## 6. 공통 위젯

### MessageBubble (lib/features/chat/presentation/widgets/message_bubble.dart)
- 사용자: 우측, primaryContainer 배경, 우하단 라운드 작음
- AI: 좌측, surfaceContainerHighest 배경, 좌하단 라운드 작음
- 최대 너비 75%
- AI 메시지에 mic(따라말하기), volume_up(TTS) 버튼
- 길게 누르면 단어장 저장 다이얼로그
- 교정(💡) 라인 분리 표시 (앰버 박스, "wrong → right" 컬러 강조)
- 한국어 힌트 괄호는 회색 톤
- 타이핑 중 점 3개 애니메이션

### ChatInputBar (lib/features/chat/presentation/widgets/chat_input_bar.dart)
- 좌측 마이크 버튼 (원형, 활성 시 빨강+크기증가 애니메이션)
- 중앙 TextField (라운드 24)
- 우측 send IconButton
- 상단에 STT 중간결과 표시 영역
- 상단 그림자 (offset: 0,-1)

### SuggestionChips (lib/features/chat/presentation/widgets/suggestion_chips.dart)
- "Try saying..." 라벨
- 각 제안: 영어(노란색 #FFD54F) + 한글(파란색 #64B5F6, 작은 글자)
- 우측 volume_up 버튼
- 카드형 (반투명 surfaceContainerHighest, outline border, 라운드 12)

### StreakBadge (lib/features/streak/presentation/widgets/streak_badge.dart)
- 불꽃 아이콘 + streak 숫자 + 미니 CircularProgress (오늘 진행률)
- 목표 달성 시 오렌지 강조

### AvatarWidget (lib/features/chat/presentation/widgets/avatar_widget.dart)
- 120x120 dotLottie 애니메이션 ("talking girl.lottie")
- AI 응답 중일 때만 재생

### BannerAdWidget (lib/core/widgets/banner_ad_widget.dart)
- AdMob 배너 (모든 주요 화면 하단)

---

## 우선 리디자인 후보 (Phase A4에서 3개 선정)

| 후보 | 우선도 | 근거 |
|---|---|---|
| ChatScreen | ★★★ | 메인 화면, 사용 빈도 최고 |
| OnboardingScreen | ★★★ | 첫인상, 이탈률 직결 |
| SettingsScreen | ★★ | 정보 밀도 높아 리디자인 효과 큼 |
| Welcome (Chat 빈 상태) | ★★ | 첫 채팅 진입 인상 |
| WeeklyReport | ★ | 사용 빈도 낮지만 시각화 임팩트 큼 |
| Vocabulary | ★ | 학습 동기 강화 가능 |
