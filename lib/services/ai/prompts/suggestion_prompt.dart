import 'package:eng_friend/services/language/app_language.dart';

class SuggestionPrompt {
  static String build({
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
    String? lastAiMessage,
  }) {
    final native = nativeLanguage.aiName;
    final target = targetLanguage.aiName;

    final contextLine = lastAiMessage != null
        ? '\nThe tutor just said: "$lastAiMessage"\nYour suggestions MUST be direct, natural responses to this specific message.\n'
        : '';

    return '''
$contextLine
Suggest $count natural $target responses that a level $userLevel/10 learner would say NEXT in this conversation.

IMPORTANT:
- Each suggestion must be a DIRECT REPLY to the tutor's last message — not a random topic change
- Match the conversation context (if tutor asked a question, answer it; if tutor made a comment, react to it)
- Vary the style: mix answers, follow-up questions, and reactions
- Match the user's level ($userLevel/10) in vocabulary and complexity

Format as JSON array:
[{"text": "$target response", "koreanHint": "$native hint"}]
''';
  }
}
