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
        AiProviderType.groq => const [
            AiModelInfo(
              id: 'llama-3.3-70b-versatile',
              displayName: 'Llama 3.3 70B',
              description: 'Best quality, free',
            ),
            AiModelInfo(
              id: 'llama-3.1-8b-instant',
              displayName: 'Llama 3.1 8B',
              description: 'Ultra fast, free',
            ),
            AiModelInfo(
              id: 'gemma2-9b-it',
              displayName: 'Gemma 2 9B',
              description: 'Google model, free',
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

    // Free tier = Groq 백엔드. Groq와 동일한 제한 적용.
    AiProviderType.freeTier: {
      AppLanguage.chineseCantonese: const LanguageSupportInfo.limited(
        'Llama 3.3 has limited Cantonese support. Quality may be lower.',
      ),
      AppLanguage.chineseMandarin: const LanguageSupportInfo.limited(
        'Llama 3.3 Chinese quality may be lower than other models.',
      ),
      AppLanguage.italian: const LanguageSupportInfo.limited(
        'Llama 3.3 Italian quality may be lower than other models.',
      ),
    },

    // Groq (Llama 3.3) — 일부 언어 품질 제한
    AiProviderType.groq: {
      AppLanguage.chineseCantonese: const LanguageSupportInfo.limited(
        'Llama 3.3 has limited Cantonese support. Quality may be lower.',
      ),
      AppLanguage.chineseMandarin: const LanguageSupportInfo.limited(
        'Llama 3.3 Chinese quality may be lower than other models.',
      ),
      AppLanguage.italian: const LanguageSupportInfo.limited(
        'Llama 3.3 Italian quality may be lower than other models.',
      ),
    },
  };
}
