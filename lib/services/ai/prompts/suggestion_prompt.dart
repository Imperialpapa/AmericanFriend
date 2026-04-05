import 'package:eng_friend/services/language/app_language.dart';

class SuggestionPrompt {
  static String build({
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
  }) {
    final native = nativeLanguage.aiName;
    final target = targetLanguage.aiName;

    return '''
Based on the conversation above, suggest $count natural $target responses
that a level $userLevel/10 $target learner might say.

For each suggestion, provide:
1. The $target response
2. A brief $native hint

Format as JSON array:
[{"text": "$target response", "koreanHint": "$native hint"}]

Keep suggestions natural, varied in style (question, statement, reaction),
and appropriate for the user's level.
''';
  }
}
