class SuggestionPrompt {
  static String build({required int userLevel, int count = 3}) {
    return '''
Based on the conversation above, suggest $count natural English responses
that a level $userLevel/10 English learner might say.

For each suggestion, provide:
1. The English response
2. A brief Korean hint (한국어 힌트)

Format as JSON array:
[{"text": "English response", "koreanHint": "한국어 힌트"}]

Keep suggestions natural, varied in style (question, statement, reaction),
and appropriate for the user's level.
''';
  }
}
