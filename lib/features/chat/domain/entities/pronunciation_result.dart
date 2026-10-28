class PronunciationFeedback {
  final String word;
  final String issue;
  final String tip;

  const PronunciationFeedback({
    required this.word,
    this.issue = '',
    this.tip = '',
  });
}

/// 따라 읽기 발음 평가 결과.
/// 예전엔 모델 JSON을 dynamic Map 그대로 위젯에 넘겨, 형식이 조금만 어긋나도
/// build 중 TypeError가 났다(tobe A-06, ARCH-09).
class PronunciationResult {
  final int score; // 0~100
  final List<PronunciationFeedback> feedback;
  final String overall;

  const PronunciationResult({
    required this.score,
    this.feedback = const [],
    this.overall = '',
  });

  /// 점수가 없거나 숫자가 아니면 [FormatException] — 0점으로 위장하면
  /// 사용자는 자기 발음이 엉망인 줄 안다. 형식이 어긋난 feedback 항목만 버린다.
  factory PronunciationResult.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Pronunciation result is not an object');
    }
    final raw = json['score'];
    final score = switch (raw) {
      num n => n,
      String s => num.tryParse(s.trim()),
      _ => null,
    };
    if (score == null || score.isNaN || score.isInfinite) {
      throw const FormatException('Pronunciation result has no numeric score');
    }

    final items = json['feedback'];
    final feedback = <PronunciationFeedback>[
      if (items is List)
        for (final item in items)
          if (item is Map && _text(item['word']).isNotEmpty)
            PronunciationFeedback(
              word: _text(item['word']),
              issue: _text(item['issue']),
              tip: _text(item['tip']),
            ),
    ];

    return PronunciationResult(
      score: score.round().clamp(0, 100),
      feedback: feedback,
      overall: _text(json['overall']),
    );
  }

  static String _text(Object? v) => v is String ? v.trim() : '';
}
