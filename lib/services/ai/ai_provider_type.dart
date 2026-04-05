import 'package:eng_friend/services/language/app_language.dart';

enum AiProviderType {
  claude,
  openai,
  gemini,
  groq,
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
