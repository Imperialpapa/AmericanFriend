abstract class LevelConstants {
  static const int minLevel = 1;
  static const int maxLevel = 10;
  static const int defaultLevel = 1;

  /// 레벨 평가를 위한 최소 메시지 수
  static const int messagesPerAssessment = 5;

  /// 1회 평가당 최대 레벨 변동폭
  static const int maxLevelChange = 1;

  static const List<String> levelNames = [
    '', // index 0 unused
    'Absolute Beginner',
    'Beginner',
    'Elementary',
    'Pre-Intermediate',
    'Intermediate',
    'Upper Intermediate',
    'Pre-Advanced',
    'Advanced',
    'Upper Advanced',
    'Native-like',
  ];
}
