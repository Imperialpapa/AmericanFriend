# Current Design System — Korean Friend v2.2.0

> Claude Design에 전달할 현재 디자인 시스템 스냅샷
> 작성일: 2026-04-23

## 1. 테마 (lib/app.dart)

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF4A90D9),  // 청색 계열
    brightness: Brightness.light,  // 또는 dark
  ),
  useMaterial3: true,
)
```

- **Material 3 기반**, seedColor 단일 (`#4A90D9` — 차분한 미디엄 블루)
- Light/Dark 모두 같은 seed로 자동 생성
- **커스텀 ColorScheme/TextTheme 정의 없음** — Material 기본값 그대로 사용
- 시스템 폰트 (Material 기본 — Android: Roboto)
- **별도 디자인 토큰 파일 없음** — 모든 곳에서 `Theme.of(context)` 직접 호출

## 2. 색상 — 실제 사용처

### Material 시스템 색상 (Theme.of로 참조)
- `colorScheme.primary` — 마이크 버튼, send 아이콘, primary CTA
- `colorScheme.primaryContainer` — 사용자 메시지 버블 배경
- `colorScheme.surfaceContainerHighest` — AI 메시지 버블 배경, 제안 칩
- `colorScheme.onSurfaceVariant` — 보조 아이콘 색
- `colorScheme.errorContainer` — API key 없음 카드 배경
- `colorScheme.outline` — 제안 칩 테두리

### 하드코딩된 색상 (브랜드/시그널)
- `Color(0xFF4A90D9)` — 시드 컬러 (직접 사용 X, ColorScheme 통해서만)
- `Color(0xFFFFD54F)` — 제안 칩 영어 텍스트 (앰버/노란색)
- `Color(0xFF64B5F6)` — 제안 칩 한글 힌트 (라이트 블루)
- `Colors.orange` 계열 — Streak/Topic/Level 강조, 목표 달성, 일별 차트 막대
- `Colors.amber` 계열 — 미션 완료, 교정 박스
- `Colors.green` — Got it 버튼, vocabulary 마스터 상태, Active Days 통계 아이콘
- `Colors.red` 계열 — Again 버튼, 삭제 액션, 마이크 활성 상태
- `Colors.grey` — 보조 텍스트, 비활성 상태 (광범위 사용 — 일관성 약함)
- `Colors.redAccent` / `Colors.greenAccent` — 교정 표시 wrong/right

## 3. 타이포그래피

- 모두 `Theme.of(context).textTheme.*` 의 Material 기본값
- 자주 쓰는 스타일:
  - `headlineSmall` / `headlineMedium` — 페이지 타이틀
  - `titleMedium` / `titleSmall` — 섹션 헤더
  - `bodyLarge` / `bodyMedium` / `bodySmall` — 본문/설명
  - `labelSmall` — "Try saying..." 같은 미니 라벨
- 자주 쓰는 modifier:
  - `fontWeight: FontWeight.bold`
  - `color: Colors.grey` (보조 텍스트 — 약 30+ 회 반복)
  - `fontStyle: FontStyle.italic` (placeholder, "Tap to reveal")

## 4. 모양 (Shape)

- 라운드 값이 화면별로 제각각:
  - 메시지 버블: `BorderRadius.only(...)` 16/4 비대칭
  - 제안 칩: 12
  - 채팅 입력 텍스트필드: 24 (`OutlineInputBorder`)
  - 카드: Material 기본 (12)
  - 마이크 버튼: 원형
  - StreakBadge: 12
  - 토픽 경고 박스: 8
- **표준화 없음** — 각 위젯이 직접 결정

## 5. 스페이싱 / 여백

- 일관된 토큰 없음. 자주 쓰이는 값:
  - `SizedBox(height: 4 / 8 / 12 / 16 / 24 / 32 / 40)`
  - `EdgeInsets.all(8 / 12 / 16 / 24 / 32)`
  - `EdgeInsets.symmetric(horizontal: 8/12/16, vertical: 4/8/10)`
- 화면별로 patternless

## 6. 컴포넌트 패턴

| 컴포넌트 | 사용 빈도 | 특징 |
|---|---|---|
| `Card` | 높음 | 기본 elevation, 라운드 12 (Material 기본) |
| `FilledButton` | 높음 | Primary CTA |
| `OutlinedButton` | 중간 | 보조 액션 |
| `TextButton` | 중간 | Cancel, Skip 등 |
| `IconButton` | 매우 높음 | TTS, 마이크, 설정 등 |
| `SegmentedButton` | 중간 | Provider 선택, Voice gender, Suggestion mode |
| `Slider` | 중간 | Level, TTS speed, suggestion delay |
| `SwitchListTile` | 높음 | 모든 ON/OFF 설정 |
| `RadioListTile` | 중간 | AI Provider/Model 선택 |
| `DropdownButtonFormField` | 중간 | Language 선택 |
| `CircleAvatar` | 중간 | 캐릭터 'A' (모든 곳에서 단순 텍스트만) |
| `MaterialBanner` | 낮음 | 에러 표시 |
| `SnackBar` | 중간 | Streak/미션 알림 (BehaviorFloating) |

## 7. 아이콘

- **모두 Material Icons (Icons.*)** — 커스텀 아이콘셋 없음
- 자주 쓰는 것: `mic`, `send`, `volume_up`, `local_fire_department`, `emoji_events`, `topic`, `settings`, `auto_awesome`, `bolt`, `school`, `translate`, `key_off`, `close`

## 8. 애니메이션

- 메시지 입력 시 자동 스크롤 (`Curves.easeOut`, 300ms)
- 마이크 버튼 활성화 시 크기 변경 (`AnimatedContainer`, 200ms)
- 타이핑 점 3개 (`AnimationController`, 1200ms repeat, opacity)
- 아바타 Lottie (`assets/lottie/talking girl.lottie`)
- **그 외 트랜지션/마이크로 인터랙션 거의 없음**

## 9. 일러스트레이션

- 캐릭터 일러스트: **없음** — 모두 텍스트 'A' CircleAvatar
- Lottie: `talking girl.lottie` 1개 (AvatarWidget)
- 기타: 시스템 아이콘 외 자체 일러스트 없음

## 10. 종합 진단

**강점**:
- Material 3 표준 사용으로 다크모드 자동 지원
- 학습 도메인 색상 코딩 (영어=노랑, 한글=파랑, 교정=앰버) 일관성 있음

**약점 (리디자인 우선순위)**:
1. **브랜드 아이덴티티 부재** — 'A' 텍스트만 있고 캐릭터/로고 일러스트 없음
2. **시드 컬러 단일** — 학습 앱 특유의 따뜻함/재미 부족, 차분한 블루뿐
3. **디자인 토큰 미정의** — 라운드/스페이싱/컬러가 화면마다 제각각
4. **타이포 위계 약함** — 모두 Material 기본 + grey/bold 변주만
5. **마이크로 인터랙션 부족** — 정적인 화면, 학습 보상감 약함
6. **Welcome/빈 상태 디자인 단조로움** — 첫 인상 임팩트 없음

**리디자인이 노릴 트렌드 키워드** (제안):
- Vibrant + 따뜻함 (Duolingo / Cake AI 풍)
- 캐릭터 일러스트 도입 (Alex 마스코트화)
- 커스텀 컬러 팔레트 + 디자인 토큰 정립
- 학습 보상 마이크로 인터랙션 (haptic, confetti, 카운트업)
- 카드/버튼 라운드 표준화 (16-20)
