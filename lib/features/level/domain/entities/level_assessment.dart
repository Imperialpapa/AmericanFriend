class LevelAssessment {
  final int currentLevel; // 1~10
  final int suggestedLevel; // 1~10
  final String reasoning;

  const LevelAssessment({
    required this.currentLevel,
    required this.suggestedLevel,
    required this.reasoning,
  });
}
