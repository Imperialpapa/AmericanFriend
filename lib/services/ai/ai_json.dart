import 'dart:convert';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';

/// 보조 호출(레벨·제안·발음) 응답의 공통 파서.
/// 예전엔 Gemini만 코드펜스를 벗기고 나머지는 `jsonDecode(text)` + `as int`라,
/// 성공 응답도 "```json …```"이나 "7"/7.0 한 번에 실패로 떨어졌다(tobe A-06).

/// 모델 응답에서 JSON 값을 꺼내 디코드한다.
/// 코드펜스를 벗기고, 앞뒤에 설명문이 붙어도 처음으로 디코드되는 {…} 또는 […]를
/// 찾는다. 하나도 없으면 [FormatException].
Object? extractJson(String text) {
  final fenced = _fence.firstMatch(text)?.group(1);
  final candidates = [
    ?fenced,
    text.replaceAll(_fenceMarker, ''),
  ];
  for (final body in candidates) {
    for (var start = _nextOpen(body, 0);
        start != -1;
        start = _nextOpen(body, start + 1)) {
      final end = _matchingClose(body, start);
      if (end == -1) continue;
      try {
        return jsonDecode(body.substring(start, end + 1));
      } on FormatException {
        continue;
      }
    }
  }
  throw const FormatException('No JSON object or array in model output');
}

final _fence = RegExp(r'```[A-Za-z]*[ \t]*\r?\n?([\s\S]*?)```');
final _fenceMarker = RegExp(r'```[A-Za-z]*');

int _nextOpen(String s, int from) {
  for (var i = from; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x7B || c == 0x5B) return i; // { [
  }
  return -1;
}

/// [start]의 여는 괄호와 짝이 맞는 닫는 괄호 위치. 문자열 안의 괄호는 무시한다.
int _matchingClose(String s, int start) {
  final expected = <int>[];
  var inString = false;
  var escaped = false;
  for (var i = start; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == 0x5C) {
        escaped = true; // \
      } else if (c == 0x22) {
        inString = false; // "
      }
      continue;
    }
    switch (c) {
      case 0x22:
        inString = true;
      case 0x7B:
        expected.add(0x7D);
      case 0x5B:
        expected.add(0x5D);
      case 0x7D || 0x5D:
        if (expected.isEmpty || expected.removeLast() != c) return -1;
        if (expected.isEmpty) return i;
    }
  }
  return -1;
}

/// 레벨 값을 1~10 정수로. 7, 7.0, "7", 6.6 모두 받는다. 해석할 수 없으면 null.
int? parseLevel(Object? value) {
  final n = switch (value) {
    num v => v,
    String s => num.tryParse(s.trim()),
    _ => null,
  };
  if (n == null || n.isNaN || n.isInfinite) return null;
  return n.round().clamp(LevelConstants.minLevel, LevelConstants.maxLevel);
}

/// 레벨 평가 응답 → [LevelAssessment]. 절대 던지지 않는다.
/// 형식이 어긋나면 [LevelAssessment.failed] — 레벨을 바꾸지 않는다.
LevelAssessment parseLevelAssessment(String text) {
  final Object? json;
  try {
    json = extractJson(text);
  } on FormatException {
    return const LevelAssessment.failed('Unparseable assessment');
  }
  if (json is! Map) return const LevelAssessment.failed('Assessment is not an object');
  final level = parseLevel(json['suggestedLevel']);
  if (level == null) return const LevelAssessment.failed('Assessment has no level');
  final reasoning = json['reasoning'];
  return LevelAssessment(
    currentLevel: 0,
    suggestedLevel: level,
    reasoning: reasoning is String ? reasoning : '',
  );
}

/// 제안 응답 → 칩 목록. 절대 던지지 않는다. 형식이 어긋난 항목만 버린다.
List<Suggestion> parseSuggestions(String text) {
  final Object? json;
  try {
    json = extractJson(text);
  } on FormatException {
    return const [];
  }
  if (json is! List) return const [];
  return [
    for (final item in json)
      if (item is Map && item['text'] is String && (item['text'] as String).trim().isNotEmpty)
        Suggestion(
          text: item['text'] as String,
          koreanHint: item['koreanHint'] is String ? item['koreanHint'] as String : null,
        ),
  ];
}
