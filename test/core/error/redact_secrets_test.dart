import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/core/error/redact_secrets.dart';

void main() {
  group('redactSecrets', () {
    test('Gemini 키와 key= 쿼리 값을 가린다', () {
      const raw = 'Gemini (404): x\nURL: https://generativelanguage.googleapis.com'
          '/v1beta/models/m:generateContent?alt=sse&key=AIzaSyA1b2C3d4E5f6G7h8I9j0KLMNOPQRSTUV';
      final out = redactSecrets(raw);
      expect(out, isNot(contains('AIzaSyA1')));
      expect(out, contains('key=***'));
      expect(out, contains('alt=sse'));
    });

    test('Anthropic·OpenAI·Groq 키 형식을 가린다', () {
      final out = redactSecrets(
          'a sk-ant-api03-abcDEF123_xyz b sk-proj-ABCdef1234567890 c gsk_abcdEFGH12345678');
      expect(out, 'a sk-ant-*** b sk-*** c gsk_***');
    });

    test('키가 없는 문자열은 그대로 둔다', () {
      const raw = 'Free tier error (503): connectionError — skip it';
      expect(redactSecrets(raw), raw);
    });
  });
}
