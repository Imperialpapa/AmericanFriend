# Claude Design 리디자인 TODO

> 2026-04-23 시작. Claude Design (Anthropic Labs, 2026-04-17 출시)을 활용해 한국어 친구 앱 UI를 트렌디하게 리디자인하는 작업.

## 워크플로우 개요

Claude Design은 웹 제품(claude.ai/labs)이라 Claude Code에서 직접 호출 불가.
2단계 워크플로우: **(A) Claude Code에서 준비 → (B) 사용자가 Claude Design에서 생성 → (C) Claude Code에서 Flutter 포팅**

---

## Phase A. Claude Design 투입 준비 (Claude Code 작업)

- [x] **A1. 현재 화면 인벤토리 작성** ✅ `docs/design/screen_inventory.md`
- [x] **A2. 현재 디자인 시스템 추출** ✅ `docs/design/current_design_system.md`
- [x] **A3. 리디자인 목표 & 톤 정의** ✅ `docs/design/redesign_brief.md` (⚠️ 사용자 컨펌 항목 있음)
- [x] **A4. Claude Design 프롬프트 패키지 준비** ✅ `docs/design/claude_design_prompt.md`

---

## Phase B. Claude Design에서 시안 생성 (사용자 작업)

- [x] **B1~B5. Claude Design 작업 완료** ✅ `docs/design/exports/korean-friend/`
  - 채택 팔레트: **Modern Sage** (sage + beige + mustard, oklch)
  - 폰트: **Pretendard Variable**
  - 캐릭터: **Alex 페블 마스코트** (4 emotion: calm/thinking/celebrate/listening)
  - 3개 화면 시안 완료 (chat/onboarding/settings)

---

## Phase C. Flutter 포팅 (Claude Code 작업)

- [x] **C1. 시안 분석 → 포팅 플랜 수립** ✅ `docs/design/porting_plan.md` (⚠️ 사용자 결정 8개 대기)

- [x] **C2. 디자인 토큰 적용 완료** ✅
  - `lib/core/theme/` 6개 파일: app_colors / app_typography / app_radii / app_spacing / app_shadows / app_theme
  - `pubspec.yaml`: Pretendard 폰트 등록 (주석 처리, 다운로드 후 활성화)
  - `lib/app.dart`: `KFTheme.light()` / `KFTheme.dark()` 적용
  - 진단 통과 (기존 deprecation 경고만 남음)

- [x] **C3-A. Alex 페블 마스코트 위젯** ✅ `lib/core/widgets/alex_avatar.dart`
  - 비대칭 라운드 블롭 + 4 emotion (calm/thinking/celebrate/listening)
  - 그림자, 하이라이트, 머스타드 cheek blush, celebrate sparkle, thinking dots

- [x] **C3-B. 공통 위젯** ✅
  - `kf_pill.dart`, `kf_streak_chip.dart`, `kf_xp_bar.dart`

- [x] **C3-C. ChatScreen 리디자인** ✅
  - `chat_header.dart` (신규) — Alex 38px + 상태점 + 이름/컨텍스트 + StreakChip + Settings
  - `mission_strip.dart` (신규) — 미션 활성 시 진행률, 미활성 시 오늘 목표
  - `message_bubble.dart` — Modern Sage 스타일 + Learning Drawer 통합
  - `chat_input_bar.dart` — beige + 버튼 / beige rounded 텍스트필드 / sage mic+그림자
  - `suggestion_chips.dart` — 가로 스크롤 알약 형태
  - `avatar_widget.dart` — Lottie → Alex 페블로 교체
  - `chat_screen.dart` — AppBar 제거 + ChatHeader 사용, MissionStrip 추가, Welcome 메시지 새로 디자인

- [x] **C3-D. OnboardingScreen 리디자인** ✅
  - 진행 도트 + Skip + Alex 말풍선 + 컬러 강조 헤드라인 + sage CTA + Step 힌트
  - 4페이지 구조 유지 (Welcome / Language / API Key / Level)
- [x] **C3-E. SettingsScreen → "Profile" 리디자인** ✅
  - HeroCard (레벨 아바타 + Alex celebrate + XP bar + 3 stat pills)
  - 5개 섹션 그룹: Learning / AI Setup / Conversation / Voice / App
  - 언어/프로바이더/모델 선택은 BottomSheet 픽커로 변경
  - 사용 안 하는 streak_badge.dart 제거

- [ ] **C4. 실기기 검증** (Samsung Galaxy S24 Ultra)
  - 다크모드/라이트모드 양쪽
  - 작은 화면/긴 텍스트 케이스
  - 다른 기능 회귀 확인

- [ ] **C5. 커밋 & 푸시** (사용자 승인 후)

---

## 진행 로그

- 2026-04-23: 워크플로우 수립, todo.md 생성
- 2026-04-23: **Phase C4 실기기 부팅 확인** (Galaxy S26 Ultra)
  - 초기 부팅 hang 발견: `flutter_secure_storage` 복호화 실패 (BadPaddingException)
  - 원인: Android Keystore 키 불일치 (보안 업데이트/백업 복원 영향 추정, 리디자인 무관)
  - 수정: `SettingsNotifier.load()`에 PlatformException 캐치 + `deleteAll()` 자동 복구 추가
  - API 키는 재입력 필요, 다른 설정은 유지됨
- 2026-04-23: **Phase C3 전체 완료** (Chat / Onboarding / Settings 모두 Modern Sage)
  - Flutter analyze: **No issues** (deprecation 0개, error 0개)
- 2026-04-23: Phase C2 + C3-A/B/C 완료
  - Modern Sage 테마, Alex 페블, ChatScreen 전면 리디자인
  - **다음 단계**: 사용자가 빌드 검증 → OK면 C3-D (Onboarding) 진행
  - Pretendard 폰트는 미설치 (시스템 폰트 fallback). 다운로드는 `assets/fonts/README.md` 참조
- 2026-04-23: Phase B 완료 (Claude Design handoff zip 수령 & 분석)
  - Modern Sage 팔레트 채택, Pretendard, Alex 페블 마스코트
  - **단순 컬러 변경이 아닌 구조적 리디자인** — Learning Drawer, Mission Strip, Profile HeroCard 등 신설
- 2026-04-23: Phase C1 완료 — 포팅 플랜 작성, 8개 사용자 결정 항목 대기 중
- 2026-04-23: Phase A 완료 (A1~A4)
  - 현재 7개 주요 화면/위젯 구조 파악
  - 디자인 시스템 진단: 단일 시드 컬러, 토큰 미정의, 캐릭터 일러스트 부재가 주요 약점
  - 톤 키워드 결정: warm + playful + trendy modern + confident
  - 우선 리디자인 화면: Chat / Onboarding / Settings
  - Claude Design용 프롬프트 패키지 완성 (`claude_design_prompt.md`)
  - **다음 단계**: 사용자가 claude.ai/labs에서 프롬프트 입력
