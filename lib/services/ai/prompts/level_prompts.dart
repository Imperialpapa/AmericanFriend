class LevelPrompt {
  static String build() {
    return '''
Analyze the user's recent English messages and assess their English proficiency level.

Evaluate based on:
- Vocabulary range and accuracy
- Grammar complexity and correctness
- Sentence structure variety
- Natural expression usage
- Communication fluency

Respond in JSON format:
{"suggestedLevel": <1-10>, "reasoning": "<brief explanation in Korean>"}

Level guide:
1-2: Very basic (단순 단어, 기본 인사)
3-4: Elementary (간단한 문장, 기본 문법)
5-6: Intermediate (자연스러운 문장, 다양한 표현)
7-8: Upper intermediate (관용구, 복잡한 문장)
9-10: Advanced (원어민 수준, 미묘한 뉘앙스)
''';
  }
}
