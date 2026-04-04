import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/ai/claude/claude_service.dart';
import 'package:eng_friend/services/ai/openai/openai_service.dart';
import 'package:eng_friend/services/ai/gemini/gemini_service.dart';
import 'package:eng_friend/services/ai/groq/groq_service.dart';

class AiServiceFactory {
  static AiService create({
    required AiProviderType provider,
    required String apiKey,
  }) {
    return switch (provider) {
      AiProviderType.claude => ClaudeService(apiKey: apiKey),
      AiProviderType.openai => OpenAiService(apiKey: apiKey),
      AiProviderType.gemini => GeminiService(apiKey: apiKey),
      AiProviderType.groq => GroqService(apiKey: apiKey),
    };
  }
}
