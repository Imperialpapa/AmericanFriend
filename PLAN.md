# 영어 학습 앱 플랜

## 컨셉
"한국말 잘하는 미국인 친구" — AI가 미국인 캐릭터로서 영어로 대화하되, 한국어도 자연스럽게 섞어 설명해주는 영어 학습 앱

## 기술 스택
- **프론트엔드**: Flutter (모바일 앱)
- **AI 백엔드**: Claude API + OpenAI API (둘 다 사용)
- **음성**: STT (음성→텍스트) + TTS (텍스트→음성)

## 주요 기능
1. **자유 대화** — 앱 실행 시 항상 대화 가능
2. **상황별 시나리오** — 카페 주문, 면접, 여행 등 다양한 상황 연습
3. **대화 화면 표시** — 채팅 형태로 대화 내용이 화면에 표시
4. **대화 제안 기능** — 사용자 차례인데 말을 못하면, 예시 대화를 제안해줌
   - 제안 방식: 설정에서 선택 가능 (즉시 자동 / N초 후 자동 — 초 단위 설정)
5. **음성 대화** — 말하기(STT)와 듣기(TTS) 지원, 실제 회화처럼 음성으로 대화

## 레벨 시스템
- **10단계** 레벨 구분
- 사용자의 대화 수준에 따라 **실시간 자동 레벨 조정**
- 유연하게 상황에 맞춰 오르내림 (고정 레벨이 아닌 동적 조절)

## 수익 모델
- 미정 — 직접 사용해보며 기능 추가 후 결정
- 점진적 진화: 개인 학습용 → 기능 확장 → 수익형 모델로 발전

## 확장성 설계 원칙
- **모듈형 아키텍처** — 기능을 독립 모듈(플러그인)로 분리하여, 새 기능 추가 시 기존 코드에 영향 최소화
- **AI 추상화 레이어** — Claude/OpenAI를 직접 호출하지 않고 중간 레이어를 두어, 모델 교체·추가가 쉽도록
- **기능 플래그(Feature Flag)** — 새 기능을 ON/OFF 할 수 있게 하여 점진적 배포 가능
- **데이터 구조 유연성** — DB 스키마와 API를 확장 가능하게 설계 (사용자 데이터, 학습 기록, 결제 등)
- **서버 분리** — 프론트(Flutter) / API 서버 / AI 서비스를 분리하여 독립적으로 스케일링
- **수익화 대비** — 사용자 인증, 구독/결제 모듈, 사용량 추적 등을 나중에 끼워넣을 수 있는 구조로

### 예상 확장 로드맵
1. **Phase 1 (MVP)** — 자유 대화 + 음성 + 레벨 자동 조절 + 대화 제안
2. **Phase 2** — 상황별 시나리오, 학습 기록/통계, 발음 교정
3. **Phase 3** — 수익 모델 적용 (구독/인앱결제), 소셜 기능, 맞춤형 커리큘럼
4. **Phase 4+** — 사용하면서 필요한 기능 계속 추가

## 구현 진행 상황

### Phase 1 (MVP)
- [x] Flutter 프로젝트 생성 (eng_friend)
- [x] 폴더 구조 (Clean Architecture + Feature-first)
- [x] AI 추상화 레이어 (AiService, ClaudeService, OpenAiService)
- [x] 대화 파이프라인 (ConversationPipeline, SentenceSplitter, TtsQueue)
- [x] 피처 플래그 시스템
- [x] DI 설정 (Riverpod providers)
- [x] 채팅 UI 기본 구조 (ChatScreen, MessageBubble, ChatInputBar)
- [x] 시스템 프롬프트 (레벨별 가이드라인 포함)
- [x] 채팅 ↔ AI 파이프라인 연결 (ChatProvider + ConversationPipeline)
- [x] STT 연동 (VoiceProvider, 온디바이스 speech_to_text, barge-in)
- [x] TTS 파이프라인 연동 (TtsQueue 문장 단위 재생)
- [x] 레벨 자동 평가 연동 (LevelProvider, 5메시지마다 평가, 최대 1단계 변동)
- [x] 대화 제안 UI + 타이머 로직 (SuggestionProvider, SuggestionChips)
- [x] 대화 기록 로컬 저장 (Drift DB — conversations, messages, level_history)
- [x] 설정 화면 (API 키, AI 모델, 제안 모드/타이밍, TTS 속도)
- [x] 온보딩 (환영 → API 키 설정 → 레벨 선택 → 채팅 시작)

## 결정 필요 사항 (TODO)
- [ ] AI 모델 역할 분담 (Claude vs OpenAI 각각 어떤 역할?)
- [x] 음성 지원 — STT/TTS 포함 확정
- [ ] STT/TTS 엔진 선택 (Google, Whisper, Azure 등)
- [ ] 레벨 판단 기준 상세 설계
- [x] 대화 제안 트리거 — 설정에서 선택 (즉시 자동 / N초 후 자동)
- [ ] UI/UX 디자인 방향
- [ ] 백엔드 서버 구성 (Firebase? 자체 서버?)
- [ ] 상황별 시나리오 목록 정리
