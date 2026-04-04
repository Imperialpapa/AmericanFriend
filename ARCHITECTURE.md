# 프로젝트 아키텍처

## 기술 선택

| 분류 | 선택 | 이유 |
|---|---|---|
| **상태관리** | Riverpod 2.x | 컴파일 안전한 DI, AI 스트리밍에 적합한 AsyncNotifier |
| **라우팅** | go_router | 딥링크, 가드(인증) 지원 |
| **네트워크** | dio | 인터셉터(인증, 재시도, 로깅) |
| **로컬DB** | drift (SQLite) | 대화 기록, 레벨 히스토리 |
| **모델 클래스** | freezed + json_serializable | 불변 모델 + JSON 직렬화 |
| **린팅** | very_good_analysis | 엄격한 코드 품질 |

## 주요 패키지

| 카테고리 | 패키지 |
|---|---|
| AI - Claude | `anthropic_sdk_dart` 또는 `dio` 직접 호출 |
| AI - OpenAI | `openai_dart` 또는 `dart_openai` |
| STT | `speech_to_text` (온디바이스) |
| TTS | `flutter_tts` (온디바이스) |
| STT 백업 | `record` (Whisper API 폴백용 마이크 녹음) |
| 보안 저장 | `flutter_secure_storage` (API 키) |
| 설정 | `shared_preferences` (피처 플래그, 간단 설정) |
| 결제 (Phase 3) | `purchases_flutter` (RevenueCat) |
| 인증 (Phase 3) | `firebase_auth` 또는 `supabase_flutter` |

## 폴더 구조

```
lib/
├── main.dart                          # 엔트리포인트
├── main_dev.dart                      # Dev 환경
├── main_prod.dart                     # Prod 환경
├── app.dart                           # MaterialApp.router, 테마, 로컬라이제이션
│
├── core/                              # 공통 기반
│   ├── config/                        # 환경설정 (API URL, 키)
│   ├── constants/                     # 상수 (레벨 정의, 프롬프트 템플릿)
│   ├── error/                         # 에러/실패 클래스
│   ├── network/                       # Dio 클라이언트, 인터셉터
│   ├── theme/                         # 테마, 색상, 타이포그래피
│   ├── router/                        # GoRouter, 가드
│   ├── utils/                         # 확장함수, 로거, 디바운서
│   └── widgets/                       # 공용 위젯
│
├── features/                          # 기능별 모듈 (Clean Architecture)
│   ├── chat/                          # [Phase 1] 자유 대화
│   │   ├── data/                      #   모델, 데이터소스, 레포지토리 구현
│   │   ├── domain/                    #   엔티티, 추상 레포, 유스케이스
│   │   └── presentation/             #   프로바이더, 스크린, 위젯
│   │
│   ├── voice/                         # [Phase 1] 음성 (STT/TTS)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── level/                         # [Phase 1] 레벨 시스템
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── settings/                      # [Phase 1] 사용자 설정
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── onboarding/                    # [Phase 1] 첫 실행 안내 + 레벨 테스트
│   │
│   ├── scenario/                      # [Phase 2] 상황별 시나리오
│   ├── stats/                         # [Phase 2] 학습 통계
│   ├── pronunciation/                 # [Phase 2] 발음 교정
│   ├── auth/                          # [Phase 3] 인증
│   └── payment/                       # [Phase 3] 결제/구독
│
├── services/                          # 횡단 관심사 서비스
│   ├── ai/                            # ★ AI 추상화 레이어
│   │   ├── ai_service.dart            #   추상 인터페이스
│   │   ├── ai_service_factory.dart    #   팩토리 (플래그 기반 생성)
│   │   ├── claude/                    #   Claude 구현체
│   │   ├── openai/                    #   OpenAI 구현체
│   │   └── prompts/                   #   시스템 프롬프트, 레벨별 프롬프트
│   │
│   ├── feature_flags/                 # 피처 플래그
│   │   ├── feature_flag_service.dart  #   추상 인터페이스
│   │   ├── local_feature_flags.dart   #   MVP: SharedPreferences 기반
│   │   └── flags.dart                 #   플래그 키 상수
│   │
│   └── local_db/                      # 로컬 DB
│       ├── app_database.dart          #   Drift DB 정의
│       ├── daos/                      #   DAO (messages, conversations, level)
│       └── tables/                    #   테이블 정의
│
├── l10n/                              # 다국어 (ko, en)
│
└── di/                                # 의존성 주입 (Riverpod providers)
    ├── providers.dart
    ├── service_providers.dart
    └── repository_providers.dart

test/                                  # 테스트 (같은 구조 미러링)
assets/                                # 이미지, 사운드, Lottie 애니메이션
```

## AI 추상화 레이어

```dart
abstract class AiService {
  // 메시지 전송 + 응답
  Future<AiResponse> sendMessage({...});
  
  // 스트리밍 (타이핑 효과)
  Stream<String> streamMessage({...});
  
  // 레벨 평가
  Future<LevelAssessment> assessLevel({...});
  
  // 대화 제안 생성
  Future<List<Suggestion>> generateSuggestions({...});
}
```

- `ClaudeService`, `OpenAiService`가 각각 구현
- `AiServiceFactory`가 설정/피처플래그에 따라 생성
- 기능 코드는 추상 인터페이스만 의존 → 모델 교체/추가 시 기능 코드 변경 없음

## 피처 플래그 키

```dart
abstract class Flags {
  static const voiceEnabled = 'voice_enabled';           // true
  static const suggestionEnabled = 'suggestion_enabled'; // true
  static const scenarioEnabled = 'scenario_enabled';     // false (Phase 2)
  static const statsEnabled = 'stats_enabled';           // false (Phase 2)
  static const paymentEnabled = 'payment_enabled';       // false (Phase 3)
  static const useClaudeForChat = 'use_claude_for_chat'; // true
  static const useOpenaiForLevel = 'use_openai_for_level'; // false
}
```

## 대화 제안 시스템

1. AI가 응답 완료 → "사용자 차례" 상태 감지
2. 설정 확인: 즉시 / N초 후
3. 타이머 시작 (설정값에 따라)
4. 사용자가 타이핑/말하기 시작하면 → 타이머 취소
5. 타이머 만료 → AI에게 제안 요청 → 탭 가능한 칩으로 표시

## 레벨 시스템

- 매 N개 메시지마다 AI가 사용자 레벨 평가 (1~10)
- 급격한 변동 방지: 1회 평가당 최대 1단계 변경
- 현재 레벨이 AI 시스템 프롬프트에 반영 → 어휘 난이도 조절

## 실시간 대화 파이프라인 (레이턴시 최적화)

자연스러운 대화를 위해 **순차 처리가 아닌 파이프라인 병렬 처리**를 적용한다.

### 기존 문제 (순차 처리)

```
사용자 말함 → [STT 2초] → [AI API 3초] → [TTS 2초] → 앱이 말함
                        총 대기: ~7초 ❌ 대화가 아니라 기다림
```

### 해결: 스트리밍 파이프라인

```
사용자 말함
  → [온디바이스 STT] ─── 실시간 텍스트 변환 (지연 최소)
      → [AI 스트리밍 시작] ─── 토큰 단위로 수신
          → [문장1 완성 감지] → 즉시 TTS 재생 시작 🔊
          → [문장2 완성 감지] → TTS 큐에 추가 (문장1 끝나면 바로 이어서)
          → [문장3 완성 감지] → TTS 큐에 추가
          → ...
```

**체감 응답 시간: 첫 문장 도착까지 ~1~2초** ✅

### 핵심 컴포넌트: ConversationPipeline

```dart
/// 대화 루프를 총괄하는 파이프라인 오케스트레이터
class ConversationPipeline {
  final AiService aiService;
  final SttService sttService;
  final TtsService ttsService;

  /// 전체 대화 루프: 음성입력 → AI → 음성출력
  Stream<PipelineEvent> processVoiceInput(AudioStream input);
  
  /// 텍스트 입력 → AI → 음성출력
  Stream<PipelineEvent> processTextInput(String text);
}
```

```dart
/// 파이프라인 이벤트 (UI 업데이트용)
sealed class PipelineEvent {
  // STT 단계
  SttPartialResult(String partial);    // 실시간 인식 중간결과
  SttFinalResult(String text);         // 인식 완료
  
  // AI 단계
  AiTokenReceived(String token);       // 토큰 수신 (화면 타이핑 효과)
  AiSentenceComplete(String sentence); // 문장 완성
  AiResponseComplete(String full);     // 전체 응답 완료
  
  // TTS 단계
  TtsSpeakingStarted(String sentence); // TTS 재생 시작
  TtsSpeakingDone();                   // TTS 재생 완료
  
  // 에러
  PipelineError(Failure failure);
}
```

### 문장 감지 로직 (SentenceSplitter)

```dart
/// AI 스트리밍 토큰을 모아서 문장 단위로 분리
class SentenceSplitter {
  /// 토큰이 들어올 때마다 호출, 문장이 완성되면 emit
  Stream<String> feedToken(Stream<String> tokens);
}
```

- 마침표(`.`), 물음표(`?`), 느낌표(`!`) 감지 시 문장 완성으로 판단
- 약어(`Mr.`, `U.S.`) 등 오탐 방지 로직 포함
- 쉼표 뒤 일정 길이 이상이면 중간 끊기도 허용 (긴 문장 대비)

### TTS 큐 시스템 (TtsQueue)

```dart
/// 문장을 순서대로 재생하는 큐
class TtsQueue {
  /// 문장 추가 (재생 중이면 대기열에 추가, 아니면 즉시 재생)
  Future<void> enqueue(String sentence);
  
  /// 재생 중단 (사용자가 끼어들기)
  Future<void> interrupt();
  
  /// 현재 재생 상태
  Stream<TtsQueueState> get stateStream;
}
```

- 문장이 도착하는 즉시 큐에 넣고, 이전 문장 재생 끝나면 자동으로 다음 재생
- 사용자가 마이크 버튼 누르면 `interrupt()` → 즉시 중단 + 큐 비움

### 레이턴시 목표

| 구간 | 목표 | 방법 |
|---|---|---|
| 사용자 발화 → 텍스트 | < 0.5초 | 온디바이스 STT (네트워크 불필요) |
| 텍스트 → AI 첫 토큰 | < 1초 | HTTP 커넥션 풀링 + keep-alive |
| AI 첫 토큰 → 첫 문장 완성 | < 1~2초 | 스트리밍 + 문장 감지 |
| 첫 문장 → TTS 재생 시작 | < 0.3초 | 온디바이스 TTS + 프리로드 |
| **총 체감 응답 시간** | **< 2~3초** | 파이프라인 병렬 처리 |

### 추가 최적화

- **커넥션 풀링**: Dio HTTP 클라이언트에서 keep-alive 유지, 매 요청마다 핸드셰이크 방지
- **프리워밍**: 앱 시작 시 AI API에 빈 요청 보내 커넥션 미리 수립
- **사용자 끼어들기(Barge-in)**: AI가 말하는 중에 사용자가 말하면 즉시 TTS 중단 + 새 입력 처리
- **백그라운드 제안 프리페치**: AI 응답 완료 후 대화 제안을 미리 생성해두기
- **STT 폴백 전략**: 온디바이스 인식 신뢰도 낮으면 → Whisper API 자동 전환 (속도 vs 정확도 트레이드오프)

### 폴더 구조 추가

```
lib/services/
├── pipeline/
│   ├── conversation_pipeline.dart     # 대화 루프 오케스트레이터
│   ├── pipeline_event.dart            # 파이프라인 이벤트 정의
│   ├── sentence_splitter.dart         # 문장 단위 분리기
│   └── tts_queue.dart                 # TTS 재생 큐
```

## MVP에서 안 만드는 것

- 백엔드 서버 없음 (앱에서 AI API 직접 호출, 개인 사용 MVP)
- Firebase Remote Config 없음 (로컬 피처플래그로 충분)
- 인증 없음 (싱글유저, 로컬 전용)
- Phase 2/3 폴더는 빈 스텁으로만 존재
