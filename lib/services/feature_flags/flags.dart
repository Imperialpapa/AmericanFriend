abstract class Flags {
  static const voiceEnabled = 'voice_enabled';
  static const suggestionEnabled = 'suggestion_enabled';
  static const scenarioEnabled = 'scenario_enabled';
  static const statsEnabled = 'stats_enabled';
  static const paymentEnabled = 'payment_enabled';
  static const useClaudeForChat = 'use_claude_for_chat';
  static const useOpenaiForLevel = 'use_openai_for_level';

  static const Map<String, bool> defaults = {
    voiceEnabled: true,
    suggestionEnabled: true,
    scenarioEnabled: false,
    statsEnabled: false,
    paymentEnabled: false,
    useClaudeForChat: true,
    useOpenaiForLevel: false,
  };
}
