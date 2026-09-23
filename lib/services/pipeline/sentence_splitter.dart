import 'dart:async';

/// AI 스트리밍 토큰을 모아서 문장 단위로 분리
///
/// 상태를 갖지 않는다. 버퍼는 [split] 호출마다 지역 변수다 — 파이프라인은
/// 앱 전역 싱글턴이라 인스턴스 필드에 두면 취소된 턴의 잔여 텍스트가 다음 턴
/// 첫 문장에 붙고, 두 턴이 겹치면 두 응답이 글자 단위로 섞였다(tobe.md V-06).
class SentenceSplitter {
  const SentenceSplitter();

  static const _abbreviations = {'Mr.', 'Mrs.', 'Ms.', 'Dr.', 'Prof.', 'U.S.', 'e.g.', 'i.e.'};
  static final _sentenceEnd = RegExp(r'[.!?]\s');

  /// 닫히지 않은 괄호 보호의 상한. 모델이 괄호를 안 닫으면 스트림이 끝날 때까지
  /// TTS가 한 마디도 못 하므로, 이 길이를 넘으면 다음 문장 끝에서 자른다.
  static const maxUnclosedParenLength = 300;

  /// 토큰 스트림을 문장 스트림으로 변환
  Stream<String> split(Stream<String> tokens) async* {
    var buffer = '';
    // 이미 거절한(약어·괄호) 문장 끝은 다시 볼 필요가 없다. 거절 여부는
    // 그 지점까지의 텍스트로만 정해지므로 뒤에 토큰이 붙어도 바뀌지 않는다.
    var scanFrom = 0;

    await for (final token in tokens) {
      buffer += token;

      while (true) {
        int? cut;
        for (final match in _sentenceEnd.allMatches(buffer, scanFrom)) {
          final candidate = buffer.substring(0, match.end).trim();
          // 거절된 끝에서 멈추면 뒤따르는 정상 문장까지 스트림 끝까지 묶인다.
          // 계속 다음 후보를 본다.
          if (_isAbbreviation(candidate) ||
              (_hasUnclosedParenthesis(candidate) &&
                  candidate.length <= maxUnclosedParenLength)) {
            scanFrom = match.end;
            continue;
          }
          cut = match.end;
          break;
        }
        if (cut == null) break;

        final sentence = buffer.substring(0, cut).trim();
        buffer = buffer.substring(cut);
        scanFrom = 0;
        if (sentence.isNotEmpty) yield sentence;
      }
    }

    // 스트림 종료 시 남은 버퍼 처리
    final remaining = buffer.trim();
    if (remaining.isNotEmpty) {
      yield remaining;
    }
  }

  static bool _isAbbreviation(String text) {
    for (final abbr in _abbreviations) {
      if (text.endsWith(abbr)) return true;
    }
    return false;
  }

  /// 열린 괄호가 닫히지 않았는지 확인 (괄호 안 모국어 문장을 쪼개지 않기 위함)
  static bool _hasUnclosedParenthesis(String text) {
    int depth = 0;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x28) depth++; // '('
      if (text.codeUnitAt(i) == 0x29) depth--; // ')'
    }
    return depth > 0;
  }
}
