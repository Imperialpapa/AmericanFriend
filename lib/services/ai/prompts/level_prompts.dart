import 'package:eng_friend/services/language/app_language.dart';

class LevelPrompt {
  static String build({
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  }) {
    final native = nativeLanguage.aiName;
    final target = targetLanguage.aiName;

    return '''
Analyze the user's recent $target messages and assess their $target proficiency level.

Evaluate based on:
- Vocabulary range and accuracy
- Grammar complexity and correctness
- Sentence structure variety
- Natural expression usage
- Communication fluency

Respond in JSON format:
{"suggestedLevel": <1-10>, "reasoning": "<brief explanation in $native>"}

Level guide:
1-2: Very basic
3-4: Elementary
5-6: Intermediate
7-8: Upper intermediate
9-10: Advanced (native-level)
''';
  }
}
