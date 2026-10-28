class LevelAssessment {
  final int currentLevel; // 1~10
  final int suggestedLevel; // 1~10

  /// 모델이 쓴 근거. [isFailure]면 실패 사유(진단용, 사용자에게 보이지 않음).
  final String reasoning;

  /// 평가를 못 했다(네트워크·파싱 실패). suggestedLevel은 의미가 없으니
  /// 레벨에 적용하지 말 것.
  final bool isFailure;

  const LevelAssessment({
    required this.currentLevel,
    required this.suggestedLevel,
    required this.reasoning,
  }) : isFailure = false;

  /// 실패를 정상값으로 위장하지 않는다. 예전엔 5개 서비스가 실패 시
  /// suggestedLevel 5를 돌려줘 초급자가 레벨 5 쪽으로 끌려갔다(tobe A-06).
  const LevelAssessment.failed([this.reasoning = 'Assessment failed'])
      : currentLevel = 0,
        suggestedLevel = 0,
        isFailure = true;
}
