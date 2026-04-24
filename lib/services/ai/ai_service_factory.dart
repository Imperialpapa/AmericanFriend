import 'package:eng_friend/core/config/proxy_config.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/claude/claude_service.dart';
import 'package:eng_friend/services/ai/free_tier/free_tier_ai_service.dart';
import 'package:eng_friend/services/ai/openai/openai_service.dart';
import 'package:eng_friend/services/ai/gemini/gemini_service.dart';
import 'package:eng_friend/services/ai/groq/groq_service.dart';

class AiServiceFactory {
  /// [apiKey] 는 freeTier의 경우 device UUID를 담고 있음 (의미적 오버로드).
  static AiService create({
    required AiProviderType provider,
    required String apiKey,
    required String modelId,
  }) {
    return switch (provider) {
      AiProviderType.freeTier => FreeTierAiService(
          baseUrl: ProxyConfig.freeTierBaseUrl,
          deviceId: apiKey,
        ),
      AiProviderType.claude => ClaudeService(apiKey: apiKey, model: modelId),
      AiProviderType.openai => OpenAiService(apiKey: apiKey, model: modelId),
      AiProviderType.gemini => GeminiService(apiKey: apiKey, model: modelId),
      AiProviderType.groq => GroqService(apiKey: apiKey, model: modelId),
    };
  }
}
