import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/services/ai/ai_json.dart';

void main() {
  group('extractJson', () {
    test('그대로인 JSON 객체', () {
      expect(extractJson('{"suggestedLevel": 4}'), {'suggestedLevel': 4});
    });

    test('```json 코드펜스를 벗긴다', () {
      const text = '```json\n{"suggestedLevel": 6, "reasoning": "ok"}\n```';
      expect(extractJson(text), {'suggestedLevel': 6, 'reasoning': 'ok'});
    });

    test('언어 표시 없는 펜스와 앞뒤 설명문', () {
      const text = 'Here you go:\n```\n{"a": 1}\n```\nHope this helps!';
      expect(extractJson(text), {'a': 1});
    });

    test('펜스 없이 설명문에 둘러싸인 객체', () {
      const text = 'Sure! {"suggestedLevel": 3, "reasoning": "uses {braces} in text"} Thanks.';
      expect(extractJson(text),
          {'suggestedLevel': 3, 'reasoning': 'uses {braces} in text'});
    });

    test('배열(제안 칩)', () {
      const text = '```json\n[{"text": "Hi", "koreanHint": "안녕"}]\n```';
      expect(extractJson(text), [
        {'text': 'Hi', 'koreanHint': '안녕'}
      ]);
    });

    test('JSON이 아닌 괄호가 먼저 나와도 다음 후보를 찾는다', () {
      const text = 'Note [draft]: {"score": 80}';
      expect(extractJson(text), {'score': 80});
    });

    test('JSON이 없으면 FormatException', () {
      expect(() => extractJson('no json here'), throwsFormatException);
      expect(() => extractJson('{"broken": '), throwsFormatException);
    });
  });

  group('parseLevel', () {
    test('정수·실수·숫자 문자열을 받는다', () {
      expect(parseLevel(7), 7);
      expect(parseLevel(7.0), 7);
      expect(parseLevel(6.6), 7);
      expect(parseLevel('7'), 7);
      expect(parseLevel(' 4.4 '), 4);
    });

    test('범위를 벗어나면 1~10으로 자른다', () {
      expect(parseLevel(0), 1);
      expect(parseLevel(-3), 1);
      expect(parseLevel(15), 10);
      expect(parseLevel('11'), 10);
    });

    test('해석할 수 없으면 null', () {
      expect(parseLevel(null), isNull);
      expect(parseLevel('seven'), isNull);
      expect(parseLevel(true), isNull);
      expect(parseLevel('NaN'), isNull);
    });
  });

  group('parseLevelAssessment', () {
    test('펜스로 감싼 문자열 레벨도 성공', () {
      final a = parseLevelAssessment(
          '```json\n{"suggestedLevel": "8", "reasoning": "good"}\n```');
      expect(a.isFailure, isFalse);
      expect(a.suggestedLevel, 8);
      expect(a.reasoning, 'good');
    });

    test('파싱 실패는 레벨 5가 아니라 failed', () {
      for (final text in [
        'I think level 5',
        '{"reasoning": "no level"}',
        '[1, 2]',
        '{"suggestedLevel": "high"}',
      ]) {
        final a = parseLevelAssessment(text);
        expect(a.isFailure, isTrue, reason: text);
      }
    });
  });

  group('parseSuggestions', () {
    test('형식이 어긋난 항목만 버린다', () {
      final s = parseSuggestions(
          '[{"text": "Yes!"}, {"koreanHint": "no text"}, "raw", {"text": "  "}, {"text": "Sure", "koreanHint": 3}]');
      expect(s.map((e) => e.text), ['Yes!', 'Sure']);
      expect(s.last.koreanHint, isNull);
    });

    test('배열이 아니거나 JSON이 없으면 빈 목록', () {
      expect(parseSuggestions('{"text": "x"}'), isEmpty);
      expect(parseSuggestions('nothing'), isEmpty);
    });
  });

  group('PronunciationResult.fromJson', () {
    test('정상 응답', () {
      final r = PronunciationResult.fromJson({
        'score': 86,
        'feedback': [
          {'word': 'three', 'issue': 'TH', 'tip': '혀를 내밀어요'}
        ],
        'overall': '좋아요',
      });
      expect(r.score, 86);
      expect(r.feedback.single.word, 'three');
      expect(r.feedback.single.tip, '혀를 내밀어요');
      expect(r.overall, '좋아요');
    });

    test('점수가 없거나 숫자가 아니면 던진다 (0점으로 위장하지 않는다)', () {
      expect(() => PronunciationResult.fromJson(null), throwsFormatException);
      expect(() => PronunciationResult.fromJson([1, 2]), throwsFormatException);
      expect(() => PronunciationResult.fromJson({'feedback': []}),
          throwsFormatException);
      expect(() => PronunciationResult.fromJson({'score': 'great'}),
          throwsFormatException);
    });

    test('문자열·실수 점수를 받고 0~100으로 자른다', () {
      expect(PronunciationResult.fromJson({'score': '72'}).score, 72);
      expect(PronunciationResult.fromJson({'score': 88.6}).score, 89);
      expect(PronunciationResult.fromJson({'score': 140}).score, 100);
      expect(PronunciationResult.fromJson({'score': -5}).score, 0);
    });

    test('형식이 어긋난 feedback 항목은 버리고 나머지는 살린다', () {
      final r = PronunciationResult.fromJson({
        'score': 60,
        'feedback': [
          'not a map',
          {'issue': 'no word'},
          {'word': 42},
          {'word': 'very', 'issue': 'V/B', 'tip': null},
        ],
        'overall': 7,
      });
      expect(r.feedback.map((f) => f.word), ['very']);
      expect(r.feedback.single.tip, '');
      expect(r.overall, '');
    });

    test('feedback이 목록이 아니어도 점수는 살린다', () {
      final r = PronunciationResult.fromJson({'score': 95, 'feedback': 'none'});
      expect(r.score, 95);
      expect(r.feedback, isEmpty);
    });

    test('extractJson과 이어서: 펜스로 감싼 응답', () {
      final r = PronunciationResult.fromJson(extractJson(
          '```json\n{"score": 91, "feedback": [], "overall": "Great"}\n```'));
      expect(r.score, 91);
    });
  });
}
