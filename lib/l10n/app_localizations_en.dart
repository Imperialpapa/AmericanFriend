// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Korean Friend';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied!';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String chatWelcomeTitle(String name) {
    return 'Hey! I\'m $name';
  }

  @override
  String chatWelcomeSubtitle(String language) {
    return 'I\'m here to help you practice $language.\nLet\'s start a conversation!';
  }

  @override
  String get chatApiKeyRequiredTitle => 'API Key Required';

  @override
  String get chatApiKeyRequiredBody =>
      'To start chatting, you need an AI API key.\nSet one up in Settings.';

  @override
  String get chatApiKeyGoToSettings => 'Go to Settings';

  @override
  String get chatErrorGoToSettings => 'Settings';

  @override
  String chatHeaderContext(int day, int level, String name) {
    return 'Day $day · Lv.$level $name';
  }

  @override
  String chatInputHintTyping(String language) {
    return 'Type or tap mic in $language…';
  }

  @override
  String get chatInputHintListening => 'Listening…';

  @override
  String get chatSuggestionTitle => 'Try saying…';

  @override
  String get chatMessageTapToReveal => 'Tap to reveal';

  @override
  String get chatDrawerHear => 'Hear it';

  @override
  String get chatDrawerTry => 'Try';

  @override
  String get chatDrawerSave => 'Save';

  @override
  String get chatCorrectionPrefix => 'You said ';

  @override
  String get chatCorrectionArrow => ' → try ';

  @override
  String get chatSaveToVocabTitle => 'Save to Vocabulary';

  @override
  String get chatSaveToVocabHint => 'Edit expression to save';

  @override
  String get chatSaveToVocabDone => 'Saved to vocabulary!';

  @override
  String get chatUserMenuPractice => 'Practice pronunciation';

  @override
  String get chatUserMenuSave => 'Save to vocabulary';

  @override
  String chatStreakGoalReached(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Daily goal reached! Streak: $_temp0';
  }

  @override
  String chatMissionComplete(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars',
      one: '1 star',
    );
    return 'Mission Complete! +$_temp0';
  }

  @override
  String missionStripTodayGoal(int today, int goal) {
    return 'Today\'s goal · $today of $goal';
  }

  @override
  String missionStripGoalReached(int today, int goal) {
    return 'Goal reached · $today of $goal';
  }

  @override
  String missionStripActive(int turn, int total) {
    return 'Mission · $turn of $total';
  }

  @override
  String missionStripToGo(int n) {
    return '+$n to go';
  }

  @override
  String get missionStripDone => '✓ Done';

  @override
  String onboardStepOf(int step, int total) {
    return 'Step $step of $total · About 30 seconds';
  }

  @override
  String get onboardCtaLetsGo => 'Let\'s go';

  @override
  String get onboardCtaStartChatting => 'Start chatting';

  @override
  String get onboardWelcomeSubtitle =>
      'Your friendly language tutor.\nLet\'s practice through real chats.';

  @override
  String get onboardLanguageBubble => 'First — what\'s your language setup?';

  @override
  String get onboardLanguageHeadline1 => 'Set your\n';

  @override
  String get onboardLanguageHeadline2 => 'native & target';

  @override
  String get onboardLanguageHeadline3 => '.';

  @override
  String get onboardLanguageHelp =>
      'I\'ll detect your native from device, but you can change it.';

  @override
  String get onboardLanguageNativeLabel => 'Your native language';

  @override
  String get onboardLanguageTargetLabel => 'Language to learn';

  @override
  String get onboardLanguageMustDiffer =>
      'Native and target must be different.';

  @override
  String get onboardApiBubble =>
      'I need an API key to chat — both options are free.';

  @override
  String get onboardApiHeadline1 => 'Get your\n';

  @override
  String get onboardApiHeadline2 => 'free key';

  @override
  String get onboardApiHeadline3 => '.';

  @override
  String get onboardApiHelp => 'No credit card. Takes about a minute.';

  @override
  String get onboardApiGeminiDesc => 'Gemini · 1,500 requests/day free';

  @override
  String get onboardApiGroqDesc =>
      'Groq (Llama 3.3) · 14,400 requests/day, ultra fast';

  @override
  String get onboardApiStep1Title => 'Open the key page';

  @override
  String get onboardApiStep1Action => 'Open in browser';

  @override
  String get onboardApiStep2Title => 'Create & copy the key';

  @override
  String get onboardApiStep2Sub => 'Sign in → create new key → copy';

  @override
  String get onboardApiStep3Title => 'Paste it here';

  @override
  String get onboardApiKeyHint => 'Your API key';

  @override
  String get onboardApiPaste => 'Paste';

  @override
  String get onboardApiFreeTierHint => 'Or skip — you get 20 free messages/day';

  @override
  String get onboardLevelBubble =>
      'How much can you say already? It auto-adjusts as we chat.';

  @override
  String get onboardLevelHeadline1 => 'Where do\n';

  @override
  String get onboardLevelHeadline2 => 'you start';

  @override
  String get onboardLevelHeadline3 => '?';

  @override
  String get onboardLevelBeginner => 'Beginner';

  @override
  String get onboardLevelNative => 'Native';

  @override
  String get settingsHeaderTitle => 'Profile';

  @override
  String get settingsSectionLearning => 'Learning';

  @override
  String get settingsSectionAi => 'AI Setup';

  @override
  String get settingsSectionConversation => 'Conversation';

  @override
  String get settingsSectionVoice => 'Voice';

  @override
  String get settingsSectionApp => 'App';

  @override
  String settingsHeroLevelLearner(int level) {
    return 'Level $level Learner';
  }

  @override
  String get settingsStatStreak => 'Streak';

  @override
  String get settingsStatStreakSub => 'days';

  @override
  String get settingsStatWords => 'Words';

  @override
  String get settingsStatWordsSub => 'saved';

  @override
  String get settingsStatToday => 'Today';

  @override
  String settingsStatTodaySub(int goal) {
    return '/ $goal';
  }

  @override
  String get settingsRowVocabulary => 'Vocabulary';

  @override
  String get settingsRowVocabularyDetail => 'Saved words';

  @override
  String get settingsRowWeeklyReport => 'Weekly report';

  @override
  String get settingsRowWeeklyReportDetail => 'Last 7 days';

  @override
  String get settingsRowLevel => 'Level';

  @override
  String get settingsRowNativeLanguage => 'Native language';

  @override
  String get settingsRowTargetLanguage => 'Target language';

  @override
  String get settingsRowProvider => 'Provider';

  @override
  String get settingsRowModel => 'Model';

  @override
  String get settingsRowApiKey => 'API key';

  @override
  String settingsGetFreeKey(String hint) {
    return 'Get free key at $hint';
  }

  @override
  String get settingsApiKeyHint => 'paste your key…';

  @override
  String get settingsPickerProvider => 'AI Provider';

  @override
  String get settingsPickerModel => 'Model';

  @override
  String settingsShowTargetText(String language) {
    return 'Show $language text';
  }

  @override
  String get settingsShowTargetTextSub => 'Display AI response on screen';

  @override
  String settingsShowNativeTranslation(String language) {
    return 'Show $language translation';
  }

  @override
  String get settingsShowNativeTranslationSub => 'Inline hints in parentheses';

  @override
  String get settingsSuggestionTiming => 'Suggestion timing';

  @override
  String get settingsSuggestionImmediate => 'Immediate';

  @override
  String get settingsSuggestionDelayed => 'Delayed';

  @override
  String settingsReadTargetAloud(String language) {
    return 'Read $language aloud';
  }

  @override
  String get settingsReadTranslationAloud => 'Read translation aloud';

  @override
  String get settingsVoiceGender => 'Voice gender';

  @override
  String get settingsVoiceFemale => 'Female';

  @override
  String get settingsVoiceMale => 'Male';

  @override
  String get settingsSpeed => 'Speed';

  @override
  String get settingsSpeedSlow => 'Slow';

  @override
  String get settingsSpeedNormal => 'Normal';

  @override
  String get settingsSpeedFast => 'Fast';

  @override
  String get settingsMicPause => 'Mic pause tolerance';

  @override
  String get settingsMicPauseSub => 'How long you can pause mid-sentence';

  @override
  String get settingsMicPauseQuick => 'Quick 3s';

  @override
  String get settingsMicPauseNormal => 'Normal 5s';

  @override
  String get settingsMicPausePatient => 'Patient 8s';

  @override
  String get settingsAutoSendVoice => 'Auto-send voice';

  @override
  String get settingsAutoSendVoiceSub =>
      'Off: tap send to confirm what you said';

  @override
  String get settingsDailyReminder => 'Daily reminder';

  @override
  String settingsDailyReminderOn(String time) {
    return 'At $time';
  }

  @override
  String get settingsDailyReminderOff => 'Get nudged to practice';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsSendFeedback => 'Send feedback';

  @override
  String get settingsSendFeedbackDetail => 'Email';

  @override
  String get settingsFeedbackEmailFailed => 'Could not open email app';

  @override
  String get levelDesc1 => '1 sentence, basic words';

  @override
  String get levelDesc2 => '1-2 sentences, everyday words';

  @override
  String get levelDesc3 => '2 sentences, simple phrases';

  @override
  String get levelDesc4 => '2-3 sentences, common idioms';

  @override
  String get levelDesc5 => '2-3 sentences, natural conversation';

  @override
  String get levelDesc6 => '3-4 sentences, idioms & phrasal verbs';

  @override
  String get levelDesc7 => '3-4 sentences, rich vocabulary';

  @override
  String get levelDesc8 => '4-5 sentences, advanced expressions';

  @override
  String get levelDesc9 => '4-5 sentences, near-native nuance';

  @override
  String get levelDesc10 => '5 sentences, full native level';

  @override
  String get startupError => 'Startup error';

  @override
  String get startupContinueAnyway => 'Continue anyway';

  @override
  String get vocabTitle => 'My Vocabulary';

  @override
  String vocabTabAll(int count) {
    return 'All ($count)';
  }

  @override
  String vocabTabReview(int count) {
    return 'Review ($count)';
  }

  @override
  String get vocabCaughtUp => 'All caught up!';

  @override
  String get vocabCaughtUpSub => 'No words to review right now.';

  @override
  String get vocabListEmpty =>
      'No words saved yet.\nLong-press text in chat or tap + to add.';

  @override
  String get vocabAddTitle => 'Add Word';

  @override
  String get vocabFieldExpression => 'Expression';

  @override
  String get vocabFieldExpressionHint => 'e.g. break the ice';

  @override
  String get vocabFieldMeaning => 'Meaning';

  @override
  String get vocabFieldMeaningHint => 'e.g. to start a conversation';

  @override
  String get vocabButtonAdd => 'Add';

  @override
  String get vocabReviewComplete => 'Review complete!';

  @override
  String get vocabReviewTapReveal => 'Tap to reveal';

  @override
  String get vocabReviewAgain => 'Again';

  @override
  String get vocabReviewGotIt => 'Got it';

  @override
  String get reportTitle => 'Weekly Report';

  @override
  String get reportSectionDaily => 'Daily Activity';

  @override
  String get reportSectionTopics => 'Topics Practiced';

  @override
  String get reportSectionLevels => 'Level Changes';

  @override
  String get reportNoTopics =>
      'No topic sessions this week.\nTry the Topic Focus mode!';

  @override
  String get reportNoLevels => 'No level changes this week.';

  @override
  String get reportStatMessages => 'Messages';

  @override
  String get reportStatActiveDays => 'Active Days';

  @override
  String get reportStatStreak => 'Streak';

  @override
  String reportTurns(int turns) {
    return '$turns turns';
  }

  @override
  String reportLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get topicSheetTitle => 'Choose a Topic';

  @override
  String get topicTodayLabel => 'Today\'s Topic';

  @override
  String get topicActive => 'Active';

  @override
  String get topicCategoryDaily => 'Daily Life';

  @override
  String get topicCategoryTravel => 'Travel';

  @override
  String get topicCategoryFood => 'Food & Dining';

  @override
  String get topicCategoryWork => 'Work & Business';

  @override
  String get topicCategoryShopping => 'Shopping';

  @override
  String get topicCategoryHealth => 'Health';

  @override
  String get topicCategorySocial => 'Social';

  @override
  String get topicCategoryEntertainment => 'Entertainment';

  @override
  String get missionSheetTitle => 'Missions';

  @override
  String get missionDifficultyEasy => 'Easy';

  @override
  String get missionDifficultyMedium => 'Medium';

  @override
  String get missionDifficultyHard => 'Hard';

  @override
  String missionTurnsNeeded(int turns) {
    return '$turns turns needed';
  }

  @override
  String get pronSheetTitle => 'Repeat After Me';

  @override
  String get pronListenFirst => 'Listen first';

  @override
  String get pronReadyHint => 'Tap the mic and read the sentence aloud';

  @override
  String get pronListening => 'Listening...';

  @override
  String get pronEvaluating => 'Evaluating your pronunciation...';

  @override
  String get pronTryAgain => 'Try Again';

  @override
  String get pronDetails => 'Details';

  @override
  String get pronScoreExcellent => 'Excellent!';

  @override
  String get pronScoreGood => 'Good!';

  @override
  String get pronScoreKeepPracticing => 'Keep practicing';

  @override
  String get pronScoreNeedsWork => 'Needs work';

  @override
  String pronError(String message) {
    return 'Error: $message';
  }
}
