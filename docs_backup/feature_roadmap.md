# EngFriend Feature Roadmap — 꾸준한 학습 유도 기능

> 작성일: 2026-04-06

## Phase 1: Daily Streak (일일 연속 학습)
- 매일 최소 N개 문장을 말하면 streak +1
- 연속 일수 표시 (불꽃 아이콘) — AppBar 또는 채팅 화면 상단
- streak 끊기면 리셋 → 심리적 동기부여
- DB: daily_activity 테이블 (date, messageCount, streakCount)
- 상태: SharedPreferences + DB

## Phase 2: Topic System (주제 시스템)
### 오늘의 주제
- 매일 새로운 상황/주제 카드 제공
- 주제 선택 시 Alex가 해당 상황으로 대화 시작

### 주제 집중 모드 (Topic Focus Mode)
- 사용자가 특정 주제 선택 → 시스템 프롬프트에 주제 고정
- Alex가 해당 상황에서 벗어나지 않고 관련 표현/어휘 집중 연습
- 종료 조건: 사용자가 "다른 주제로" 버튼 또는 말로 요청
- 세션 기록: 주제명, 대화 턴 수, 시작/종료 시간 DB 저장
- UI: AppBar에 현재 주제 표시 + 종료 버튼, 바텀시트로 주제 선택

## Phase 3: Push Notification (학습 리마인더)
- "오늘 아직 Alex와 대화하지 않았어요!" 리마인더
- 사용자 설정 시간에 알림
- flutter_local_notifications 패키지 사용

## Phase 4: Weekly Report (주간 리포트)
- 이번 주 대화 수, 사용한 문장 수, 레벨 변화 시각화
- 주제별 연습량 (턴 수, 소요 시간)
- 아직 시도하지 않은 추천 주제 표시
- 간단한 차트 (fl_chart 등)

## Phase 5: Role Play Missions (역할극 미션)
- "오늘 미션: 레스토랑에서 음식 주문하기"
- 미션 완료 조건 (특정 표현 사용, N턴 이상 대화)
- 완료 시 배지/별 획득

## Phase 6: My Vocabulary (단어장)
- 대화 중 모르는 표현 길게 눌러서 저장
- 저장된 단어/표현 복습 카드
- Spaced Repetition 알고리즘 적용
