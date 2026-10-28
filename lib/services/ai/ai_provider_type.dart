import 'package:eng_friend/services/language/app_language.dart';

/// 프로바이더별 사용 가능한 AI 모델 정의
class AiModelInfo {
  final String id;
  final String displayName;
  final String description;

  /// 이 모델의 모든 요청 본문에 합쳐 넣을 필드(대화·레벨·제안·발음 공통).
  /// thinking이 기본 ON인 모델은 끄지 않으면 max_tokens를 thinking이 먹어
  /// 보조 호출 파싱이 깨지고 음성 첫 응답이 늦어진다(tobe A-03).
  final Map<String, dynamic> requestExtras;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    this.requestExtras = const {},
  });
}

/// [body]에 [extras]를 합친 새 Map을 돌려준다. 양쪽이 Map인 키는 재귀로 합친다
/// (Gemini는 thinkingConfig가 generationConfig 안에 들어가야 해서 얕은 합치기로는 안 된다).
Map<String, dynamic> withRequestExtras(
  Map<String, dynamic> body,
  Map<String, dynamic> extras,
) {
  if (extras.isEmpty) return body;
  final merged = Map<String, dynamic>.of(body);
  extras.forEach((key, value) {
    final existing = merged[key];
    merged[key] = (existing is Map && value is Map)
        ? withRequestExtras(
            Map<String, dynamic>.from(existing),
            Map<String, dynamic>.from(value),
          )
        : value;
  });
  return merged;
}

const Map<String, dynamic> _geminiMinimalThinking = {
  'generationConfig': {
    'thinkingConfig': {'thinkingLevel': 'minimal'},
  },
};

/// 3.8 Flash는 minimal을 지원하지 않아 오류가 난다. 가장 낮은 단계가 low다.
const Map<String, dynamic> _geminiLowThinking = {
  'generationConfig': {
    'thinkingConfig': {'thinkingLevel': 'low'},
  },
};

/// GPT-6 계열은 추론 모델이고 기본 effort가 medium이다. none으로 끈다(minimal은 없다).
const Map<String, dynamic> _openAiNoReasoning = {'reasoning_effort': 'none'};

enum AiProviderType {
  freeTier,
  claude,
  openai,
  gemini,
  groq,
}

extension AiProviderModels on AiProviderType {
  /// 해당 프로바이더에서 선택 가능한 모델 목록
  List<AiModelInfo> get availableModels => switch (this) {
        AiProviderType.freeTier => const [
            AiModelInfo(
              id: 'free',
              displayName: 'Free',
              description: 'No API key needed',
            ),
          ],
        // 2026-10 라인업. 3.5 Flash-Lite($0.30/$2.50)가 가성비 기본값, 3.8 Flash($0.75/$3.75,
        // 2027-01-01부터 $1.50/$7.50)가 고품질. 3.6 Flash는 이전 세대인데 값이 3.8과 같아 뺐다.
        // 2.0-flash는 2026-06-01 셧다운, 2.5 계열은 기존 사용자 한정. 3.x는 thinking이 기본
        // ON이고 maxOutputTokens에 thought 토큰이 포함되므로 지원하는 가장 낮은 단계로 낮춘다.
        AiProviderType.gemini => const [
            AiModelInfo(
              id: 'gemini-3.5-flash-lite',
              displayName: 'Gemini 3.5 Flash-Lite',
              description: 'Fast & affordable',
              requestExtras: _geminiMinimalThinking,
            ),
            AiModelInfo(
              id: 'gemini-3.8-flash',
              displayName: 'Gemini 3.8 Flash',
              description: 'Higher quality',
              requestExtras: _geminiLowThinking,
            ),
          ],
        // 2026-10 라인업. Haiku 5.5($0.10/$0.50 per 1M, Haiku 4.5의 1/10)가 가성비 기본값,
        // Sonnet 5.5(Sonnet 5와 같은 $2/$10)가 고품질. 둘 다 thinking이 기본 ON이라 끄지
        // 않으면 max_tokens를 thinking이 먹고 음성 첫 응답이 늦어진다. 끄는 방법이 다르다:
        // - Haiku 5.5: {type: disabled}. effort가 high 이하일 때만 허용(기본 medium).
        // - Sonnet 5.5: {type: disabled}는 400. 가장 낮은 설정이 {type: between_tools}이고
        //   도구를 쓰지 않으니 thinking이 없다. thinking 안에 다른 필드를 넣으면 400.
        // 둘 다 temperature/top_p/top_k(기본값 외)와 assistant prefill이 400이다.
        AiProviderType.claude => const [
            AiModelInfo(
              id: 'claude-haiku-5-5',
              displayName: 'Claude Haiku 5.5',
              description: 'Fast & affordable',
              requestExtras: {
                'thinking': {'type': 'disabled'},
              },
            ),
            AiModelInfo(
              id: 'claude-sonnet-5-5',
              displayName: 'Claude Sonnet 5.5',
              description: 'Higher quality',
              requestExtras: {
                'thinking': {'type': 'between_tools'},
              },
            ),
          ],
        // 2026-10 라인업. gpt-4.1-nano는 2026-10-23 셧다운, gpt-4o·gpt-4o-mini는 2026-10-14
        // deprecated(2027-01-14 셧다운). OpenAI가 지정한 대체 gpt-6-luna($0.10/$0.50)가
        // 가성비 기본값, gpt-6.1-terra($1/$5, 2026-10-26 출시)가 고품질. 둘 다 Chat
        // Completions·스트리밍 지원. max_tokens(deprecated)와 temperature(effort none일 때만
        // 허용)는 보내지 않는다.
        AiProviderType.openai => const [
            AiModelInfo(
              id: 'gpt-6-luna',
              displayName: 'GPT-6 Luna',
              description: 'Fast & affordable',
              requestExtras: _openAiNoReasoning,
            ),
            AiModelInfo(
              id: 'gpt-6.1-terra',
              displayName: 'GPT-6.1 Terra',
              description: 'Higher quality',
              requestExtras: _openAiNoReasoning,
            ),
          ],
        // 2026-06-17 Groq가 llama-3.3-70b-versatile / llama-3.1-8b-instant를 폐기.
        // gemma2-9b-it도 현행 카탈로그에서 사라짐. 셋 다 호출하면 model_not_found(404).
        // Groq 공식 권장 대체 모델이 openai/gpt-oss-120b.
        // qwen3.8-27b(2026-10 추가)는 Preview라 예고 없이 내려갈 수 있어 기본값으로 두지
        // 않는다 — 내려가면 서버 MODEL_MIGRATIONS_JSON으로 gpt-oss-120b에 옮긴다.
        // reasoning이 기본 OFF라 reasoning_effort를 보내지 않는다(GroqService).
        AiProviderType.groq => const [
            AiModelInfo(
              id: 'openai/gpt-oss-120b',
              displayName: 'GPT-OSS 120B',
              description: 'Reliable, free',
            ),
            AiModelInfo(
              id: 'qwen/qwen3.8-27b',
              displayName: 'Qwen 3.8 27B',
              description: 'Newest, free (preview)',
            ),
            AiModelInfo(
              id: 'openai/gpt-oss-20b',
              displayName: 'GPT-OSS 20B',
              description: 'Ultra fast, free',
            ),
          ],
      };

  /// 기본 모델 ID
  String get defaultModelId => availableModels.first.id;

  /// 모델 ID가 유효한지 확인, 유효하지 않으면 기본 모델 반환
  String resolveModelId(String? modelId) {
    if (modelId == null) return defaultModelId;
    final exists = availableModels.any((m) => m.id == modelId);
    return exists ? modelId : defaultModelId;
  }

  /// 모델별 요청 추가 필드. 목록에 없는 ID면 아무것도 붙이지 않는다.
  Map<String, dynamic> requestExtrasFor(String modelId) {
    for (final m in availableModels) {
      if (m.id == modelId) return m.requestExtras;
    }
    return const {};
  }
}

/// AI 모델별 언어 지원 수준
enum LanguageSupportLevel {
  /// 완전 지원
  full,

  /// 동작하지만 품질이 낮을 수 있음
  limited,
}

/// 모델-언어 조합의 지원 정보
class LanguageSupportInfo {
  final LanguageSupportLevel level;
  final String? warningMessage;

  const LanguageSupportInfo.full()
      : level = LanguageSupportLevel.full,
        warningMessage = null;

  const LanguageSupportInfo.limited(this.warningMessage)
      : level = LanguageSupportLevel.limited;
}

extension AiProviderLanguageSupport on AiProviderType {
  /// 특정 언어의 지원 수준 조회
  LanguageSupportInfo supportFor(AppLanguage language) {
    final limited = _limitedLanguages[this];
    if (limited != null && limited.containsKey(language)) {
      return limited[language]!;
    }
    return const LanguageSupportInfo.full();
  }

  /// 대상 언어 기준 경고 여부 확인
  bool hasWarningFor(AppLanguage language) {
    return supportFor(language).level == LanguageSupportLevel.limited;
  }

  /// 모델별 제한 언어 매핑
  static final Map<AiProviderType, Map<AppLanguage, LanguageSupportInfo>>
      _limitedLanguages = {
    // Gemini, Claude, OpenAI — 전체 지원
    AiProviderType.gemini: {},
    AiProviderType.claude: {},
    AiProviderType.openai: {},

    // Free tier = 자체 프록시 백엔드. 업스트림 모델은 서버가 결정한다.
    // 모델명을 문구에 박지 말 것 — 서버 환경변수로 바뀌면 즉시 거짓말이 된다.
    AiProviderType.freeTier: {
      AppLanguage.chineseCantonese: const LanguageSupportInfo.limited(
        'Cantonese support on the free model may be limited. Quality may be lower.',
      ),
      AppLanguage.chineseMandarin: const LanguageSupportInfo.limited(
        'Chinese quality on the free model may be lower than premium models.',
      ),
      AppLanguage.italian: const LanguageSupportInfo.limited(
        'Italian quality on the free model may be lower than premium models.',
      ),
    },

    // Groq — 소형 오픈 모델이라 일부 언어 품질 제한 가능
    AiProviderType.groq: {
      AppLanguage.chineseCantonese: const LanguageSupportInfo.limited(
        'Cantonese support may be limited on this model. Quality may be lower.',
      ),
      AppLanguage.chineseMandarin: const LanguageSupportInfo.limited(
        'Chinese quality may be lower than premium models.',
      ),
      AppLanguage.italian: const LanguageSupportInfo.limited(
        'Italian quality may be lower than premium models.',
      ),
    },
  };
}
