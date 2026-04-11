import 'package:eng_friend/services/language/app_language.dart';

class PronunciationPrompt {
  static String build({
    required String originalText,
    required String spokenText,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  }) {
    final native = nativeLanguage.aiName;
    final target = targetLanguage.aiName;

    return '''
You are a pronunciation coach for $native speakers learning $target.

Compare the ORIGINAL sentence with the user's SPOKEN result (captured by speech-to-text).
Analyze pronunciation issues.

ORIGINAL: "$originalText"
SPOKEN:   "$spokenText"

Common issues for $native speakers to check:
- L/R confusion
- F/P confusion
- V/B confusion
- TH sounds (θ/ð)
- Word stress and intonation
- Linking and reduction (gonna, wanna, I'd)
- Missing or added syllables
- Vowel pronunciation

Respond in this EXACT JSON format (no markdown code blocks):
{"score": <1-100>, "feedback": [{"word": "<problematic word>", "issue": "<what went wrong>", "tip": "<how to fix, in $native>"}], "overall": "<one sentence overall comment in $native>"}

Rules:
- Score 90-100: Almost perfect
- Score 70-89: Good with minor issues
- Score 50-69: Needs practice
- Score below 50: Significant issues
- If original and spoken are identical or nearly identical, give score 95+ and empty feedback array
- Maximum 3 feedback items
- Keep tips practical and brief
''';
  }
}
