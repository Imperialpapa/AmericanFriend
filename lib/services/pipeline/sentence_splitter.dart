import 'dart:async';

/// AI 스트리밍 토큰을 모아서 문장 단위로 분리
class SentenceSplitter {
  static const _abbreviations = {'Mr.', 'Mrs.', 'Ms.', 'Dr.', 'Prof.', 'U.S.', 'e.g.', 'i.e.'};
  static final _sentenceEnd = RegExp(r'[.!?]\s');

  String _buffer = '';

  /// 토큰 스트림을 문장 스트림으로 변환
  Stream<String> split(Stream<String> tokens) async* {
    await for (final token in tokens) {
      _buffer += token;

      while (true) {
        final match = _sentenceEnd.firstMatch(_buffer);
        if (match == null) break;

        final endIndex = match.end;
        final candidate = _buffer.substring(0, endIndex).trim();

        // 약어 오탐 방지
        if (_isAbbreviation(candidate)) {
          break;
        }

        // 괄호 안에서는 문장을 분리하지 않음 (모국어 텍스트 보호)
        if (_hasUnclosedParenthesis(candidate)) {
          break;
        }

        yield candidate;
        _buffer = _buffer.substring(endIndex);
      }
    }

    // 스트림 종료 시 남은 버퍼 처리
    final remaining = _buffer.trim();
    if (remaining.isNotEmpty) {
      yield remaining;
    }
    _buffer = '';
  }

  bool _isAbbreviation(String text) {
    for (final abbr in _abbreviations) {
      if (text.endsWith(abbr)) return true;
    }
    return false;
  }

  /// 열린 괄호가 닫히지 않았는지 확인
  bool _hasUnclosedParenthesis(String text) {
    int depth = 0;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x28) depth++; // '('
      if (text.codeUnitAt(i) == 0x29) depth--; // ')'
    }
    return depth > 0;
  }

  void reset() {
    _buffer = '';
  }
}
