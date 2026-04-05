# 발음 평가 & 레벨 테스트 확장 — 심층 분석

## 1. 발음 평가 (Pronunciation Assessment)

### 현재 상태
- `speech_to_text` 패키지로 STT 구현 완료 (`voice_provider.dart`)
- 사용자 음성 → 텍스트 변환만 수행, 발음 정확도 평가 없음

### 구현 방식 비교

#### 방식 A: AI 기반 발음 평가 (추천)
**원리**: 사용자에게 특정 문장을 읽게 하고, STT 결과와 원문을 비교하여 AI가 분석

```
[원문] "I'd like to grab a cup of coffee"
[STT 결과] "I like to grab a cup of copy"
→ AI가 차이점 분석: "I'd" → "I" (축약형 누락), "coffee" → "copy" (f/p 발음 혼동)
```

**장점**:
- 추가 API/패키지 불필요 (기존 Gemini + STT만 사용)
- 한국인 특화 피드백 가능 (AI 프롬프트로 제어)
- 즉시 구현 가능

**단점**:
- STT 엔진 자체의 보정으로 실제 발음 오류가 가려질 수 있음
- 음소(phoneme) 단위 정밀 평가 어려움

**구현 계획**:
1. 새 엔티티: `PronunciationResult` (원문, STT결과, 점수, 피드백 목록)
2. 새 프롬프트: `PronunciationPrompt` — 원문 vs STT 비교 분석 지시
3. 새 위젯: `PronunciationPractice` — 문장 표시 → 녹음 → 결과 표시
4. 흐름:
   - AI 응답 중 문장을 선택하면 "따라 읽기" 모드 진입
   - 사용자가 문장을 읽음 (STT)
   - 원문과 STT 결과를 Gemini에 보내 차이점 분석
   - 점수 + 한국인 특화 피드백 표시

**AI 프롬프트 설계**:
```
Compare the original sentence with the user's spoken result (from STT).
Analyze pronunciation issues, especially common for Korean speakers:
- L/R confusion (라/러)
- F/P confusion (프/ㅍ)
- V/B confusion (브/ㅂ)  
- TH sounds (θ/ð)
- Word stress and intonation
- Linking and reduction (gonna, wanna, I'd)

Score: 1-100
Return JSON: {"score": N, "feedback": [{"word": "...", "issue": "...", "tip": "..."}]}
```

#### 방식 B: 전용 발음 평가 API
**후보**:
- **Azure Speech SDK** (`pronunciation_assessment`) — 음소 단위 평가, 정확도/유창성/완전성 점수
- **Google Cloud Speech-to-Text v2** — `word_confidence` 필드 활용

**장점**: 음소 단위 정밀 평가, 신뢰도 점수 제공
**단점**: 추가 API 키/비용 필요, 패키지 추가 복잡도

#### 추천: 방식 A → B 순차 적용
- 1단계: AI 기반으로 빠르게 구현 (현재 인프라만으로 가능)
- 2단계: 사용자 피드백 후 Azure Speech SDK 등으로 정밀도 향상

### 코드 변경 범위

```
lib/
├── features/pronunciation/
│   ├── domain/entities/
│   │   └── pronunciation_result.dart     # 평가 결과 엔티티
│   ├── presentation/
│   │   ├── providers/
│   │   │   └── pronunciation_provider.dart  # 상태 관리
│   │   └── widgets/
│   │       ├── pronunciation_card.dart      # 따라읽기 카드
│   │       └── pronunciation_result_view.dart # 결과 표시
│   └── services/
│       └── pronunciation_evaluator.dart     # 평가 로직
├── services/ai/prompts/
│   └── pronunciation_prompt.dart            # 발음 평가 프롬프트 (신규)
```

**기존 파일 변경**:
- `message_bubble.dart` — 문장 탭 시 "따라 읽기" 모드 진입 버튼 추가
- `ai_service.dart` — `evaluatePronunciation()` 메서드 추가
- `gemini_service.dart` — 구현

---

## 2. 레벨 테스트 확장

### 현재 상태
- `level_provider.dart`: 사용자 메시지 5개마다 자동 평가
- `level_prompts.dart`: 텍스트 기반 평가만 수행 (어휘, 문법, 문장구조)
- `LevelAssessment`: suggestedLevel + reasoning만 반환
- 최대 1단계씩만 변동 (`maxLevelChange = 1`)

### 현재 한계점
1. **텍스트만 평가** — 발음, 듣기 이해도 미반영
2. **단일 지표** — 1~10 숫자 하나로만 평가
3. **수동 테스트 없음** — 자동 평가만 존재, 사용자가 직접 테스트 불가
4. **평가 이력 없음** — DB에 기록하지만 UI에서 확인 불가
5. **온보딩 레벨 설정** — 자기 신고식 (정확하지 않음)

### 확장 설계

#### 2-1. 멀티 스킬 평가 체계

현재 단일 레벨 → **4개 영역별 레벨**로 확장:

| 영역 | 평가 방법 | 데이터 소스 |
|------|-----------|-------------|
| **Speaking** | 발음 평가 점수 + 문장 복잡도 | 발음 평가 기능 |
| **Listening** | AI 질문에 대한 응답 적절성 | 대화 맥락 분석 |
| **Grammar** | 문법 오류 빈도/유형 | AI 대화 분석 |
| **Vocabulary** | 어휘 다양성 + 난이도 | 사용자 메시지 분석 |

```dart
class LevelAssessment {
  final int overallLevel;       // 종합 (1~10)
  final int speakingLevel;      // 말하기 (1~10)
  final int listeningLevel;     // 듣기 (1~10)
  final int grammarLevel;       // 문법 (1~10)
  final int vocabularyLevel;    // 어휘 (1~10)
  final String reasoning;
  final List<String> strengths;     // 잘하는 점
  final List<String> improvements;  // 개선할 점
  final DateTime assessedAt;
}
```

#### 2-2. 수동 레벨 테스트 (온디맨드)

사용자가 직접 "레벨 테스트" 버튼을 눌러 체계적 평가:

**테스트 흐름**:
```
1단계: 듣기 (AI가 문장 읽어줌 → 사용자가 의미 선택 / 받아쓰기)
2단계: 읽기 (영어 지문 → 이해도 질문)
3단계: 말하기 (주어진 문장 따라 읽기 → 발음 평가)
4단계: 작문 (주제에 대해 3-5문장 작성 → AI 평가)
```

**테스트 문항 생성**: Gemini에 레벨별 문항 생성 요청
```
Generate a listening comprehension question for level 5/10 English learner.
Provide: 1 sentence to read aloud, 4 multiple choice options for meaning.
Format: JSON {"sentence": "...", "options": [...], "correct": 0, "koreanHint": "..."}
```

#### 2-3. 레벨 히스토리 & 시각화

```
lib/
├── features/level/
│   ├── domain/entities/
│   │   └── level_assessment.dart         # 확장 (4영역)
│   │   └── level_test_question.dart      # 테스트 문항 (신규)
│   ├── presentation/
│   │   ├── screens/
│   │   │   └── level_test_screen.dart    # 수동 테스트 화면 (신규)
│   │   │   └── level_history_screen.dart # 이력 화면 (신규)
│   │   ├── widgets/
│   │   │   └── level_indicator.dart      # 기존 (확장)
│   │   │   └── level_radar_chart.dart    # 레이더 차트 (신규)
│   │   │   └── level_history_graph.dart  # 변화 그래프 (신규)
│   │   └── providers/
│   │       └── level_provider.dart       # 기존 (확장)
│   │       └── level_test_provider.dart  # 테스트 상태 관리 (신규)
```

**DB 테이블 확장**:
```sql
-- 기존 level_history_table 확장
CREATE TABLE level_history (
  id INTEGER PRIMARY KEY,
  overall_level INTEGER,
  speaking_level INTEGER,
  listening_level INTEGER,
  grammar_level INTEGER,
  vocabulary_level INTEGER,
  reasoning TEXT,
  strengths TEXT,       -- JSON array
  improvements TEXT,    -- JSON array
  test_type TEXT,       -- 'auto' | 'manual'
  assessed_at DATETIME
);
```

---

## 3. 구현 우선순위 (단계별)

### Phase 1 (즉시 구현 가능)
1. **AI 기반 발음 평가** — 메시지 버블에 "따라 읽기" 버튼, STT vs 원문 비교
2. **수동 레벨 테스트 버튼** — Settings 또는 채팅 화면에서 접근

### Phase 2 (1~2주)
3. **멀티 스킬 평가 체계** — LevelAssessment 확장, 프롬프트 개선
4. **레벨 히스토리** — DB 저장 + 그래프 UI

### Phase 3 (선택)
5. **Azure Speech SDK 연동** — 음소 단위 정밀 발음 평가
6. **레이더 차트** — 4개 영역별 실력 시각화

---

## 4. 기술적 고려사항

### 발음 평가
- STT `confidence` 값 활용 가능 (`speech_to_text`의 `recognizedWords` 외에 `confidence` 필드)
- STT가 잘 인식 못하는 단어 = 발음이 안 좋은 단어로 간주 가능
- TTS 속도를 느리게 해서 원문을 먼저 들려주고 따라 읽게 하면 학습 효과 증가

### 레벨 테스트
- 테스트 문항은 캐싱하여 API 호출 최소화
- 테스트 중 네트워크 끊김 대비: 로컬에 진행 상태 저장
- 온보딩 시 간단한 3문항 테스트로 초기 레벨 정확도 향상 가능

### API 비용
- 발음 평가 1회 = Gemini API 1회 호출 (저비용)
- 수동 레벨 테스트 = 4~5회 호출 (문항 생성 + 평가)
- 무료 tier(1,500 req/day) 내에서 충분히 운영 가능
