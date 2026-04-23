# Flutter 포팅 플랜 — Claude Design Modern Sage

> Claude Design 시안 → Flutter 위젯 변환 매핑
> 작성일: 2026-04-23
> ⚠️ **사용자 승인 후 C2 진행**

## 📌 시안 핵심 요약

Claude Design이 단순 컬러 변경이 아닌 **구조적 리디자인**을 제안했음:

1. **Modern Sage 팔레트 채택** — 세이지 그린 + 베이지 + 머스타드, oklch 컬러스페이스
2. **Pretendard 폰트** — 한글/영어 모두 자연스러운 모던 산세리프
3. **Alex 마스코트 신설** — 추상 페블 형태(border-radius 블롭), 감정 4종 (calm/thinking/celebrate/listening)
4. **채팅 화면 신설**:
   - 헤더에 "Day 14 · Cafe chat" 컨텍스트
   - **Mission Strip** (오늘의 미션 + XP bar)
   - **Learning Drawer** — Alex 메시지 아래 펼쳐지는 학습 패널 (번역/발음/교정/Hear it/Save word를 통합)
5. **온보딩 신설** — 진행 도트, Alex 말풍선, 큰 헤드라인(컬러 강조), 4종 Goal Card
6. **설정 → "Profile" 신설** — 사용자 프로필 HeroCard, 3 stat pills, Learning/Alex/App 그룹 카드

## ⚠️ 사용자 결정 필요 사항

포팅 전에 다음 항목 컨펌 필요:

### 1. 시안의 가짜 데이터를 어떻게 처리할까?
시안에는 실제 앱에 없는 요소가 포함됨:
- **사용자 프로필** ("지호 · Jiho", 이메일) — **현재 앱에 사용자 계정 시스템 없음**
- **XP/레벨 시스템** ("1,240 / 3,000 XP", "B1") — **현재 앱은 1~10 레벨만 있음**
- **Mission Strip** ("Today's mission · 2 of 3") — 미션 기능 있지만 진행률 형식 다름
- **Voice & accent** ("US · Warm") — 현재 Female/Male만 있음
- **Goal/Conversation style** — 현재 앱에 없는 개념

**옵션**:
- (A) 시안 그대로 가져가고 신규 기능 백로그에 추가
- (B) 시안의 시각적 요소만 가져오고 데이터는 현재 앱 모델로 매핑 (예: XP→Level, profile→generic)
- (C) 일부만 (예: HeroCard는 현재 데이터로, Mission Strip은 보류)

**추천**: **(B)** — 시각 톤은 유지하되 현재 데이터 모델로 매핑. 신규 기능(프로필/XP)은 별도 의사결정.

### 2. 캐릭터 변경
- 현재 `talking girl.lottie` (여성 캐릭터) → 시안의 추상 페블 마스코트로 교체할까?
- 옵션: Lottie 유지 + 페블은 보조 / 페블로 완전 교체 / 두 개 토글

**추천**: 페블로 교체 (브랜드 일관성). Lottie는 향후 재도입 가능.

### 3. AppBar 액션 위치
시안 헤더에는 Topics/Missions/Settings 아이콘이 없음 (back chevron + StreakChip + stats만).
- 현재 앱은 Topics/Missions를 AppBar에서 진입함
- 옵션: 시안의 미니멀 헤더 + Mission Strip(이미 있음)으로 대체 / Topics/Missions를 별도 진입점 추가

**추천**: 시안대로 진행. Mission Strip이 미션 진입을 대체. Topics는 chat reminders/goal로 흡수 또는 + 버튼(composer left)에 추가.

### 4. Pretendard 폰트 도입
- pubspec.yaml에 폰트 에셋 추가 + assets/fonts/ 폴더에 폰트 파일 배치 필요
- 무료 폰트 (오픈소스) — 다운로드/포함 OK?

**추천**: Yes. Pretendard Variable Font 1개 파일이면 충분.

---

## 🗺️ 포팅 매핑표

### Phase C2: 디자인 토큰 (Flutter 테마)

신규 파일: `lib/core/theme/`
- `app_colors.dart` — Modern Sage 라이트/다크 컬러 정의
- `app_typography.dart` — Pretendard 기반 TextTheme
- `app_radii.dart` — 라운드 토큰 (xs:6, sm:10, md:14, lg:18, xl:24, full:999)
- `app_spacing.dart` — 8pt 그리드 (4/8/12/16/20/24/32/40)
- `app_shadows.dart` — 라이트모드 카드/CTA용 그림자
- `app_theme.dart` — ThemeData 통합 (Material 3 위에 커스텀)

**oklch → Flutter Color 변환**:
- Flutter는 oklch 미지원 → 헥사로 사전 변환 (대략적 sRGB 매핑)
- 변환표는 `app_colors.dart` 헤더에 주석으로 보존

**Pretendard 폰트 추가**:
- `pubspec.yaml`에 폰트 등록
- `assets/fonts/Pretendard-Variable.ttf` 다운로드 후 배치
- TextTheme의 `fontFamily`에 적용

### Phase C3-A: Alex 마스코트 위젯

신규: `lib/core/widgets/alex_avatar.dart`
- Flutter에는 CSS `border-radius: 58% 42% 55% 45% / 50% 55% 45% 50%` 같은 비대칭 라운드 직접 지원 X
- **구현 방법**:
  - **옵션 1**: `ClipPath` + 커스텀 Path로 페블 형태 그리기
  - **옵션 2**: SVG 아이콘 4종 (감정별)을 에셋으로 추가 후 `flutter_svg`로 렌더
  - **옵션 3**: `Container` + `BorderRadius.only(...)`로 대각선 4값을 흉내 (근사치)
- **추천**: **옵션 1** (CustomPainter) — 가장 충실하게 시안 재현, 감정별 변형 코드로 처리
- 매개변수: `size`, `emotion` (enum: calm/thinking/celebrate/listening), 다크모드는 Theme에서 자동
- 추가 효과: gradient body, 흰색 highlight, 머스타드 cheek blush, 그림자

### Phase C3-B: 공통 위젯 (ui-bits)

신규: `lib/core/widgets/`
- `pill.dart` — 알약 라벨 (`StreakChip` 재사용)
- `streak_chip.dart` — 머스타드 배경 + 작은 flame SVG + 일수
- `xp_bar.dart` — 3px 얇은 progress bar
- `app_icon.dart` — 시안의 모노 라인 아이콘 24개를 SVG로 정리 (또는 Material Icons 매핑표)
  - 시안에 있는 것: chat, home, profile, book, stats, bell, mic, send, sparkle, translate, chevr, chevd, close, check, plus, play, ear, wave, globe, moon, heart, lock, trash, bolt, cards, target
  - **추천**: 단순화를 위해 가능한 한 Material Icons 매핑, 부족한 것만 SVG 추가

### Phase C3-C: ChatScreen 리디자인

수정: `lib/features/chat/presentation/screens/chat_screen.dart`
수정: `lib/features/chat/presentation/widgets/message_bubble.dart`
수정: `lib/features/chat/presentation/widgets/chat_input_bar.dart`
수정: `lib/features/chat/presentation/widgets/suggestion_chips.dart`

**위젯 매핑**:
| Claude Design 요소 | Flutter 구현 위치 | 비고 |
|---|---|---|
| `ChatHeader` | `chat_screen.dart` AppBar 영역 교체 | back chevron, Alex 34px+상태점, 이름+컨텍스트, StreakChip, stats |
| `MissionStrip` | 새 위젯 `mission_strip.dart` | sage-wash 카드, target 아이콘, XP bar, +XP 라벨 |
| Time separator "Today · 8:14 AM" | _buildMessageList에 날짜 그룹화 헤더 추가 | uppercase tiny |
| `AlexMsg` + Learning Drawer | `message_bubble.dart` 리팩토링 | drawer는 expand 상태로 conditional |
| `UserMsg` | `message_bubble.dart` 사용자 분기 | sage bg, white text, radius 18/18/6/18 |
| `SuggestionRow` | `suggestion_chips.dart` 가로 스크롤로 변경 | 알약 형태 |
| `Composer` | `chat_input_bar.dart` 재구성 | + 버튼(beige), 텍스트필드(beige rounded), mic(sage circle+shadow) |
| `AdBand` | 기존 BannerAdWidget 유지 | 시각만 정리 |

**MessageBubble의 Learning Drawer 통합**:
- 현재: 교정(💡)이 메시지 본문 안에 박스로 들어감
- 신규: 교정 + 번역 + 발음 + Hear/Save 버튼이 통합된 Drawer 카드 (메시지 아래)
- 옵션: 자동 펼침 (첫 메시지) / 메시지 탭 시 토글
- **추천**: 첫 메시지는 자동 펼침, 이후는 탭 시 토글 (시안 그대로)

**UserMsg 재정렬 주의**:
- 시안: User=오른쪽, sage 배경, 흰 텍스트
- 현재: User=오른쪽 (같음), primaryContainer 배경 → sage로 변경
- 액션 버튼 (mic 따라하기) 위치 검토 필요

### Phase C3-D: OnboardingScreen 리디자인

수정: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

**구조 변경**:
- 진행 도트(`OnboardingDots`) 헤더에 추가 + Skip 버튼
- 모든 페이지에 Alex 캐릭터 + 말풍선 패턴 적용
- 큰 헤드라인 + 컬러 강조 (`<span style={{ color: c.sageDeep }}>`)
- 하단 고정 CTA 버튼 (52px, sage, 그림자)
- 페이지 하단에 "Step X of 4 · About Y seconds" 컨텍스트 힌트

**기존 4페이지 (Welcome → Language → API Key → Level) 어떻게 매핑?**:
- 시안은 step 2를 "Goal picker"로 보여줌 — **현재 앱에 Goal 개념 없음**
- **결정 필요**: Goal 페이지를 신설할지 / 기존 Welcome/Language/API/Level만 새 디자인으로 입힐지
- **추천**: 기존 4페이지 유지 + 시안의 비주얼 패턴(Alex+말풍선+큰헤드라인+컨펌카드+CTA)을 각 페이지에 적용

### Phase C3-E: SettingsScreen 리디자인 (→ "Profile")

수정: `lib/features/settings/presentation/screens/settings_screen.dart`

**구조 변경**:
- 타이틀 "Settings" → **"Profile"** 변경
- 상단 close 버튼 (X)
- **HeroCard 신설** — 사용자 정보 + Alex celebrate + 3 stat pills
- **3개 Group 카드**:
  - **Learning**: Vocabulary, Weekly report, Goal(?), Learning language
  - **Alex**: Conversation style(?), Voice & accent, Chat reminders
  - **App**: Appearance, Privacy & data(?), Rate Korean Friend
- 기존 설정들 재배치:
  - Native/Target Language → Learning > Learning language (확장 시 dropdown)
  - Level → Learning > Goal에 흡수 또는 별도 행
  - AI Model + Model Version + API Key → 별도 그룹 신설 ("AI Provider"?) — 시안에 없음, **결정 필요**
  - Conversation Suggestions → Alex > Conversation style에 흡수
  - Show text/translation, TTS, Avatar 등 → Alex 그룹 또는 App 그룹
  - Daily Reminder → Alex > Chat reminders
  - Feedback → App > 또는 별도 footer 행

**미해결 항목**:
- 사용자 계정 정보 ("지호 · Jiho · 이메일") — 현재 앱에 없음
  - 옵션 (B) 적용: 익명 + level 표시로 대체 ("Learner · Level 5")
- AI Provider 설정 — 시안에 없는 그룹. App 그룹에 추가 또는 신규 "Advanced" 그룹

### Phase C3-F: 광고 배너

- `BannerAdWidget` 그대로 유지
- 시안의 `AdBand` placeholder는 시각 가이드 (상단 hairline border, beige tile pattern은 placeholder 디자인)

---

## 📅 작업 순서 (Phase C 세분화)

C2 → C3-A → C3-B → C3-C → C3-D → C3-E → C4 → C5

| Step | 내용 | 예상 변경 파일 수 | 위험도 |
|---|---|---|---|
| C2 | 디자인 토큰 + Pretendard | 6개 신규 + pubspec | 낮음 |
| C3-A | Alex 페블 위젯 | 1개 신규 | 중간 (CustomPaint) |
| C3-B | 공통 위젯 (Pill/StreakChip/XPBar/Icon) | 4개 신규 | 낮음 |
| C3-C | ChatScreen + 하위 위젯들 | 4개 수정 + 1개 신규(MissionStrip) | **높음** (Learning Drawer 신설) |
| C3-D | OnboardingScreen | 1개 수정 | 중간 |
| C3-E | SettingsScreen → ProfileScreen | 1개 대폭 수정 | **높음** (정보 아키텍처 변경) |
| C4 | 실기기 검증 | - | 중간 |
| C5 | 커밋 & 푸시 | - | 낮음 |

각 Step 완료 시 사용자에게 보고하고, 실기기 빌드는 C2/C3-A 완료 후 한 번, 그리고 모든 화면 완료 후 한 번.

---

## ❓ 사용자 답변 요청 (체크리스트)

C2 시작 전에 다음 결정이 필요합니다:

- [ ] **시안 가짜 데이터 처리**: (A) 그대로 / **(B) 시각만 차용 + 현재 데이터 매핑** / (C) 부분 적용 → **추천 B**
- [ ] **캐릭터 교체**: Lottie 제거하고 페블 마스코트로 통일? → **추천 Yes**
- [ ] **AppBar 액션**: Topics/Missions/Settings 아이콘 위치 — Mission Strip + composer + 라우팅으로 대체? → **추천 Yes**
- [ ] **Pretendard 폰트 다운로드 OK?** → **추천 Yes** (오픈소스, ~1MB)
- [ ] **온보딩**: 기존 4페이지 유지 + 시각 패턴만 적용? (Goal 페이지는 신설 X) → **추천 Yes**
- [ ] **Settings → "Profile" 이름 변경 OK?** → 시안 그대로
- [ ] **AI Provider/Model/Key 설정 위치**: 새 "Advanced" 그룹 vs App 그룹 흡수 → **추천 신규 "Advanced"** (전문 사용자용)
- [ ] **사용자 프로필 (이름/이메일) 도입**: 시안의 HeroCard에 무엇을 표시? → **추천**: 익명 + Level + 학습 통계만 (계정 시스템 신설 X)
