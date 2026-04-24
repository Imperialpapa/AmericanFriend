// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Korean Friend';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonContinue => '다음';

  @override
  String get commonSkip => '건너뛰기';

  @override
  String get commonCopy => '복사';

  @override
  String get commonCopied => '복사됨!';

  @override
  String get commonSettings => '설정';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDone => '완료';

  @override
  String chatWelcomeTitle(String name) {
    return '안녕! 난 $name이야';
  }

  @override
  String chatWelcomeSubtitle(String language) {
    return '$language 연습을 도와줄게.\n대화를 시작해보자!';
  }

  @override
  String get chatApiKeyRequiredTitle => 'API 키가 필요해요';

  @override
  String get chatApiKeyRequiredBody =>
      '대화를 시작하려면 AI API 키가 필요해요.\n설정에서 추가해 주세요.';

  @override
  String get chatApiKeyGoToSettings => '설정으로 이동';

  @override
  String get chatErrorGoToSettings => '설정';

  @override
  String chatHeaderContext(int day, int level, String name) {
    return '$day일째 · Lv.$level $name';
  }

  @override
  String chatInputHintTyping(String language) {
    return '$language로 입력하거나 마이크를 누르세요…';
  }

  @override
  String get chatInputHintListening => '듣는 중…';

  @override
  String get chatSuggestionTitle => '이렇게 말해보세요…';

  @override
  String get chatMessageTapToReveal => '탭하여 보기';

  @override
  String get chatDrawerHear => '듣기';

  @override
  String get chatDrawerTry => '따라하기';

  @override
  String get chatDrawerSave => '저장';

  @override
  String get chatCorrectionPrefix => '';

  @override
  String get chatCorrectionArrow => ' → ';

  @override
  String get chatSaveToVocabTitle => '단어장에 저장';

  @override
  String get chatSaveToVocabHint => '저장할 표현을 편집하세요';

  @override
  String get chatSaveToVocabDone => '단어장에 저장됨!';

  @override
  String get chatUserMenuPractice => '발음 연습';

  @override
  String get chatUserMenuSave => '단어장에 저장';

  @override
  String chatStreakGoalReached(int days) {
    return '오늘 목표 달성! 연속 $days일째';
  }

  @override
  String chatMissionComplete(int stars) {
    return '미션 완료! +$stars★';
  }

  @override
  String missionStripTodayGoal(int today, int goal) {
    return '오늘의 목표 · $today / $goal';
  }

  @override
  String missionStripGoalReached(int today, int goal) {
    return '목표 달성 · $today / $goal';
  }

  @override
  String missionStripActive(int turn, int total) {
    return '미션 · $turn / $total';
  }

  @override
  String missionStripToGo(int n) {
    return '+$n 남음';
  }

  @override
  String get missionStripDone => '✓ 완료';

  @override
  String onboardStepOf(int step, int total) {
    return '$step / $total 단계 · 약 30초 소요';
  }

  @override
  String get onboardCtaLetsGo => '시작하기';

  @override
  String get onboardCtaStartChatting => '대화 시작';

  @override
  String get onboardWelcomeSubtitle => '친근한 언어 튜터예요.\n실제 대화로 연습해요.';

  @override
  String get onboardLanguageBubble => '먼저 — 언어 설정을 해볼까요?';

  @override
  String get onboardLanguageHeadline1 => '';

  @override
  String get onboardLanguageHeadline2 => '모국어 & 학습 언어';

  @override
  String get onboardLanguageHeadline3 => '를 골라요.';

  @override
  String get onboardLanguageHelp => '기기 설정에서 모국어를 자동 감지했지만, 바꿀 수 있어요.';

  @override
  String get onboardLanguageNativeLabel => '모국어';

  @override
  String get onboardLanguageTargetLabel => '배울 언어';

  @override
  String get onboardLanguageMustDiffer => '모국어와 학습 언어는 달라야 해요.';

  @override
  String get onboardApiBubble => '대화하려면 API 키가 필요해요 — 둘 다 무료예요.';

  @override
  String get onboardApiHeadline1 => '';

  @override
  String get onboardApiHeadline2 => '무료 키';

  @override
  String get onboardApiHeadline3 => '를 받아요.';

  @override
  String get onboardApiHelp => '신용카드 필요 없어요. 1분이면 돼요.';

  @override
  String get onboardApiGeminiDesc => 'Gemini · 1일 1,500회 무료';

  @override
  String get onboardApiGroqDesc => 'Groq (Llama 3.3) · 1일 14,400회, 초고속';

  @override
  String get onboardApiStep1Title => '키 발급 페이지 열기';

  @override
  String get onboardApiStep1Action => '브라우저에서 열기';

  @override
  String get onboardApiStep2Title => '키 생성 & 복사';

  @override
  String get onboardApiStep2Sub => '로그인 → 새 키 생성 → 복사';

  @override
  String get onboardApiStep3Title => '여기 붙여넣기';

  @override
  String get onboardApiKeyHint => 'API 키';

  @override
  String get onboardApiPaste => '붙여넣기';

  @override
  String get onboardApiFreeTierHint => '또는 건너뛰기 — 하루 20회 무료 제공';

  @override
  String get onboardLevelBubble => '지금 얼마나 말할 수 있나요? 대화하면서 자동으로 맞춰져요.';

  @override
  String get onboardLevelHeadline1 => '';

  @override
  String get onboardLevelHeadline2 => '어디서 시작';

  @override
  String get onboardLevelHeadline3 => '할까요?';

  @override
  String get onboardLevelBeginner => '초급';

  @override
  String get onboardLevelNative => '원어민';

  @override
  String get settingsHeaderTitle => '프로필';

  @override
  String get settingsSectionLearning => '학습';

  @override
  String get settingsSectionAi => 'AI 설정';

  @override
  String get settingsSectionConversation => '대화';

  @override
  String get settingsSectionVoice => '음성';

  @override
  String get settingsSectionApp => '앱';

  @override
  String settingsHeroLevelLearner(int level) {
    return 'Level $level 학습자';
  }

  @override
  String get settingsStatStreak => '연속';

  @override
  String get settingsStatStreakSub => '일';

  @override
  String get settingsStatWords => '단어';

  @override
  String get settingsStatWordsSub => '저장됨';

  @override
  String get settingsStatToday => '오늘';

  @override
  String settingsStatTodaySub(int goal) {
    return '/ $goal';
  }

  @override
  String get settingsRowVocabulary => '단어장';

  @override
  String get settingsRowVocabularyDetail => '저장된 단어';

  @override
  String get settingsRowWeeklyReport => '주간 리포트';

  @override
  String get settingsRowWeeklyReportDetail => '최근 7일';

  @override
  String get settingsRowLevel => '레벨';

  @override
  String get settingsRowNativeLanguage => '모국어';

  @override
  String get settingsRowTargetLanguage => '학습 언어';

  @override
  String get settingsRowProvider => '제공자';

  @override
  String get settingsRowModel => '모델';

  @override
  String get settingsRowApiKey => 'API 키';

  @override
  String settingsGetFreeKey(String hint) {
    return '무료 키 받기 · $hint';
  }

  @override
  String get settingsApiKeyHint => '키를 붙여넣으세요…';

  @override
  String get settingsPickerProvider => 'AI 제공자';

  @override
  String get settingsPickerModel => '모델';

  @override
  String settingsShowTargetText(String language) {
    return '$language 텍스트 표시';
  }

  @override
  String get settingsShowTargetTextSub => 'AI 답변 화면에 표시';

  @override
  String settingsShowNativeTranslation(String language) {
    return '$language 번역 표시';
  }

  @override
  String get settingsShowNativeTranslationSub => '괄호 안 인라인 힌트';

  @override
  String get settingsSuggestionTiming => '제안 시점';

  @override
  String get settingsSuggestionImmediate => '즉시';

  @override
  String get settingsSuggestionDelayed => '지연';

  @override
  String settingsReadTargetAloud(String language) {
    return '$language 음성 재생';
  }

  @override
  String get settingsReadTranslationAloud => '번역 음성 재생';

  @override
  String get settingsVoiceGender => '음성 성별';

  @override
  String get settingsVoiceFemale => '여성';

  @override
  String get settingsVoiceMale => '남성';

  @override
  String get settingsSpeed => '속도';

  @override
  String get settingsSpeedSlow => '느림';

  @override
  String get settingsSpeedNormal => '보통';

  @override
  String get settingsSpeedFast => '빠름';

  @override
  String get settingsMicPause => '마이크 멈춤 허용';

  @override
  String get settingsMicPauseSub => '말 도중에 멈출 수 있는 시간';

  @override
  String get settingsMicPauseQuick => '빠름 3초';

  @override
  String get settingsMicPauseNormal => '보통 5초';

  @override
  String get settingsMicPausePatient => '여유 8초';

  @override
  String get settingsAutoSendVoice => '음성 자동 전송';

  @override
  String get settingsAutoSendVoiceSub => '끄면: 확인 후 전송 버튼을 눌러요';

  @override
  String get settingsDailyReminder => '매일 알림';

  @override
  String settingsDailyReminderOn(String time) {
    return '$time';
  }

  @override
  String get settingsDailyReminderOff => '매일 연습 알림 받기';

  @override
  String get settingsReminderTime => '알림 시간';

  @override
  String get settingsSendFeedback => '피드백 보내기';

  @override
  String get settingsSendFeedbackDetail => '이메일';

  @override
  String get settingsFeedbackEmailFailed => '이메일 앱을 열 수 없어요';

  @override
  String get levelDesc1 => '1문장, 기초 단어';

  @override
  String get levelDesc2 => '1-2문장, 일상 단어';

  @override
  String get levelDesc3 => '2문장, 간단한 표현';

  @override
  String get levelDesc4 => '2-3문장, 일반 관용구';

  @override
  String get levelDesc5 => '2-3문장, 자연스러운 대화';

  @override
  String get levelDesc6 => '3-4문장, 관용구 & 구동사';

  @override
  String get levelDesc7 => '3-4문장, 풍부한 어휘';

  @override
  String get levelDesc8 => '4-5문장, 고급 표현';

  @override
  String get levelDesc9 => '4-5문장, 원어민에 가까운 뉘앙스';

  @override
  String get levelDesc10 => '5문장, 완전한 원어민 수준';

  @override
  String get startupError => '시작 오류';

  @override
  String get startupContinueAnyway => '무시하고 계속';

  @override
  String get vocabTitle => '내 단어장';

  @override
  String vocabTabAll(int count) {
    return '전체 ($count)';
  }

  @override
  String vocabTabReview(int count) {
    return '복습 ($count)';
  }

  @override
  String get vocabCaughtUp => '다 했어요!';

  @override
  String get vocabCaughtUpSub => '지금 복습할 단어가 없어요.';

  @override
  String get vocabListEmpty => '저장된 단어가 없어요.\n채팅에서 길게 눌러 저장하거나 +를 눌러 추가하세요.';

  @override
  String get vocabAddTitle => '단어 추가';

  @override
  String get vocabFieldExpression => '표현';

  @override
  String get vocabFieldExpressionHint => '예: break the ice';

  @override
  String get vocabFieldMeaning => '의미';

  @override
  String get vocabFieldMeaningHint => '예: 대화를 시작하다';

  @override
  String get vocabButtonAdd => '추가';

  @override
  String get vocabReviewComplete => '복습 완료!';

  @override
  String get vocabReviewTapReveal => '탭하여 보기';

  @override
  String get vocabReviewAgain => '다시';

  @override
  String get vocabReviewGotIt => '알았어요';

  @override
  String get reportTitle => '주간 리포트';

  @override
  String get reportSectionDaily => '일일 활동';

  @override
  String get reportSectionTopics => '연습한 주제';

  @override
  String get reportSectionLevels => '레벨 변화';

  @override
  String get reportNoTopics => '이번 주 주제 세션이 없어요.\n주제 집중 모드를 써보세요!';

  @override
  String get reportNoLevels => '이번 주 레벨 변화가 없어요.';

  @override
  String get reportStatMessages => '메시지';

  @override
  String get reportStatActiveDays => '활동일';

  @override
  String get reportStatStreak => '연속';

  @override
  String reportTurns(int turns) {
    return '$turns턴';
  }

  @override
  String reportLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get topicSheetTitle => '주제 선택';

  @override
  String get topicTodayLabel => '오늘의 주제';

  @override
  String get topicActive => '진행 중';

  @override
  String get topicCategoryDaily => '일상';

  @override
  String get topicCategoryTravel => '여행';

  @override
  String get topicCategoryFood => '음식 & 식사';

  @override
  String get topicCategoryWork => '직장 & 비즈니스';

  @override
  String get topicCategoryShopping => '쇼핑';

  @override
  String get topicCategoryHealth => '건강';

  @override
  String get topicCategorySocial => '사교';

  @override
  String get topicCategoryEntertainment => '엔터테인먼트';

  @override
  String get missionSheetTitle => '미션';

  @override
  String get missionDifficultyEasy => '쉬움';

  @override
  String get missionDifficultyMedium => '보통';

  @override
  String get missionDifficultyHard => '어려움';

  @override
  String missionTurnsNeeded(int turns) {
    return '$turns턴 필요';
  }

  @override
  String get pronSheetTitle => '따라 읽기';

  @override
  String get pronListenFirst => '먼저 듣기';

  @override
  String get pronReadyHint => '마이크를 누르고 문장을 읽어보세요';

  @override
  String get pronListening => '듣는 중...';

  @override
  String get pronEvaluating => '발음을 평가하고 있어요...';

  @override
  String get pronTryAgain => '다시 하기';

  @override
  String get pronDetails => '세부 사항';

  @override
  String get pronScoreExcellent => '훌륭해요!';

  @override
  String get pronScoreGood => '좋아요!';

  @override
  String get pronScoreKeepPracticing => '계속 연습해요';

  @override
  String get pronScoreNeedsWork => '더 연습이 필요해요';

  @override
  String pronError(String message) {
    return '오류: $message';
  }
}
