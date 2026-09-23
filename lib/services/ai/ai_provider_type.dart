import 'package:eng_friend/services/language/app_language.dart';

/// 프로바이더별 사용 가능한 AI 모델 정의
class AiModelInfo {
  final String id;
  final String displayName;
  final String description;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
  });
}

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
              description: 'No API key needed · 20 messages/day',
            ),
          ],
        AiProviderType.gemini => const [
            AiModelInfo(
              id: 'gemini-2.5-flash',
              displayName: 'Gemini 2.5 Flash',
              description: 'Fast, free tier',
            ),
            AiModelInfo(
              id: 'gemini-2.5-pro',
              displayName: 'Gemini 2.5 Pro',
              description: 'Higher quality, free tier',
            ),
            AiModelInfo(
              id: 'gemini-2.0-flash',
              displayName: 'Gemini 2.0 Flash',
              description: 'Previous gen, stable',
            ),
          ],
        AiProviderType.claude => const [
            AiModelInfo(
              id: 'claude-sonnet-4-20250514',
              displayName: 'Claude Sonnet 4',
              description: 'Best balance of speed & quality',
            ),
            AiModelInfo(
              id: 'claude-haiku-4-5-20251001',
              displayName: 'Claude Haiku 4.5',
              description: 'Fast & affordable',
            ),
            AiModelInfo(
              id: 'claude-3-5-sonnet-20241022',
              displayName: 'Claude 3.5 Sonnet',
              description: 'Previous gen, stable',
            ),
          ],
        AiProviderType.openai => const [
            AiModelInfo(
              id: 'gpt-4o',
              displayName: 'GPT-4o',
              description: 'Most capable',
            ),
            AiModelInfo(
              id: 'gpt-4o-mini',
              displayName: 'GPT-4o Mini',
              description: 'Fast & affordable',
            ),
            AiModelInfo(
              id: 'gpt-4.1-nano',
              displayName: 'GPT-4.1 Nano',
              description: 'Ultra fast, cheapest',
            ),
          ],
        // 2026-06-17 Groq가 llama-3.3-70b-versatile / llama-3.1-8b-instant를 폐기.
        // gemma2-9b-it도 현행 카탈로그에서 사라짐. 셋 다 호출하면 model_not_found(404).
        // Groq 공식 권장 대체 모델이 openai/gpt-oss-120b.
        AiProviderType.groq => const [
            AiModelInfo(
              id: 'openai/gpt-oss-120b',
              displayName: 'GPT-OSS 120B',
              description: 'Best quality, free',
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
