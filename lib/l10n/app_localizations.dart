import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Korean Friend'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get commonCopied;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @chatWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m {name}'**
  String chatWelcomeTitle(String name);

  /// No description provided for @chatWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m here to help you practice {language}.\nLet\'s start a conversation!'**
  String chatWelcomeSubtitle(String language);

  /// No description provided for @chatApiKeyRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'API Key Required'**
  String get chatApiKeyRequiredTitle;

  /// No description provided for @chatApiKeyRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'To start chatting, you need an AI API key.\nSet one up in Settings.'**
  String get chatApiKeyRequiredBody;

  /// No description provided for @chatApiKeyGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get chatApiKeyGoToSettings;

  /// No description provided for @chatErrorGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get chatErrorGoToSettings;

  /// No description provided for @chatHeaderContext.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · Lv.{level} {name}'**
  String chatHeaderContext(int day, int level, String name);

  /// No description provided for @chatInputHintTyping.
  ///
  /// In en, this message translates to:
  /// **'Type or tap mic in {language}…'**
  String chatInputHintTyping(String language);

  /// No description provided for @chatInputHintListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get chatInputHintListening;

  /// No description provided for @chatSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Try saying…'**
  String get chatSuggestionTitle;

  /// No description provided for @chatMessageTapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get chatMessageTapToReveal;

  /// No description provided for @chatDrawerHear.
  ///
  /// In en, this message translates to:
  /// **'Hear it'**
  String get chatDrawerHear;

  /// No description provided for @chatDrawerTry.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get chatDrawerTry;

  /// No description provided for @chatDrawerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get chatDrawerSave;

  /// No description provided for @chatCorrectionPrefix.
  ///
  /// In en, this message translates to:
  /// **'You said '**
  String get chatCorrectionPrefix;

  /// No description provided for @chatCorrectionArrow.
  ///
  /// In en, this message translates to:
  /// **' → try '**
  String get chatCorrectionArrow;

  /// No description provided for @chatSaveToVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to Vocabulary'**
  String get chatSaveToVocabTitle;

  /// No description provided for @chatSaveToVocabHint.
  ///
  /// In en, this message translates to:
  /// **'Edit expression to save'**
  String get chatSaveToVocabHint;

  /// No description provided for @chatSaveToVocabDone.
  ///
  /// In en, this message translates to:
  /// **'Saved to vocabulary!'**
  String get chatSaveToVocabDone;

  /// No description provided for @chatUserMenuPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice pronunciation'**
  String get chatUserMenuPractice;

  /// No description provided for @chatUserMenuSave.
  ///
  /// In en, this message translates to:
  /// **'Save to vocabulary'**
  String get chatUserMenuSave;

  /// No description provided for @chatStreakGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached! Streak: {days, plural, =1{1 day} other{{days} days}}'**
  String chatStreakGoalReached(int days);

  /// No description provided for @chatMissionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete! +{stars, plural, =1{1 star} other{{stars} stars}}'**
  String chatMissionComplete(int stars);

  /// No description provided for @missionStripTodayGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal · {today} of {goal}'**
  String missionStripTodayGoal(int today, int goal);

  /// No description provided for @missionStripGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached · {today} of {goal}'**
  String missionStripGoalReached(int today, int goal);

  /// No description provided for @missionStripActive.
  ///
  /// In en, this message translates to:
  /// **'Mission · {turn} of {total}'**
  String missionStripActive(int turn, int total);

  /// No description provided for @missionStripToGo.
  ///
  /// In en, this message translates to:
  /// **'+{n} to go'**
  String missionStripToGo(int n);

  /// No description provided for @missionStripDone.
  ///
  /// In en, this message translates to:
  /// **'✓ Done'**
  String get missionStripDone;

  /// No description provided for @onboardStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · About 30 seconds'**
  String onboardStepOf(int step, int total);

  /// No description provided for @onboardCtaLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get onboardCtaLetsGo;

  /// No description provided for @onboardCtaStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Start chatting'**
  String get onboardCtaStartChatting;

  /// No description provided for @onboardWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your friendly language tutor.\nLet\'s practice through real chats.'**
  String get onboardWelcomeSubtitle;

  /// No description provided for @onboardLanguageBubble.
  ///
  /// In en, this message translates to:
  /// **'First — what\'s your language setup?'**
  String get onboardLanguageBubble;

  /// No description provided for @onboardLanguageHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Set your\n'**
  String get onboardLanguageHeadline1;

  /// No description provided for @onboardLanguageHeadline2.
  ///
  /// In en, this message translates to:
  /// **'native & target'**
  String get onboardLanguageHeadline2;

  /// No description provided for @onboardLanguageHeadline3.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get onboardLanguageHeadline3;

  /// No description provided for @onboardLanguageHelp.
  ///
  /// In en, this message translates to:
  /// **'I\'ll detect your native from device, but you can change it.'**
  String get onboardLanguageHelp;

  /// No description provided for @onboardLanguageNativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your native language'**
  String get onboardLanguageNativeLabel;

  /// No description provided for @onboardLanguageTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Language to learn'**
  String get onboardLanguageTargetLabel;

  /// No description provided for @onboardLanguageMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'Native and target must be different.'**
  String get onboardLanguageMustDiffer;

  /// No description provided for @onboardApiBubble.
  ///
  /// In en, this message translates to:
  /// **'I need an API key to chat — both options are free.'**
  String get onboardApiBubble;

  /// No description provided for @onboardApiHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Get your\n'**
  String get onboardApiHeadline1;

  /// No description provided for @onboardApiHeadline2.
  ///
  /// In en, this message translates to:
  /// **'free key'**
  String get onboardApiHeadline2;

  /// No description provided for @onboardApiHeadline3.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get onboardApiHeadline3;

  /// No description provided for @onboardApiHelp.
  ///
  /// In en, this message translates to:
  /// **'No credit card. Takes about a minute.'**
  String get onboardApiHelp;

  /// No description provided for @onboardApiGeminiDesc.
  ///
  /// In en, this message translates to:
  /// **'Gemini · 1,500 requests/day free'**
  String get onboardApiGeminiDesc;

  /// No description provided for @onboardApiGroqDesc.
  ///
  /// In en, this message translates to:
  /// **'Groq (Llama 3.3) · 14,400 requests/day, ultra fast'**
  String get onboardApiGroqDesc;

  /// No description provided for @onboardApiStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Open the key page'**
  String get onboardApiStep1Title;

  /// No description provided for @onboardApiStep1Action.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get onboardApiStep1Action;

  /// No description provided for @onboardApiStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Create & copy the key'**
  String get onboardApiStep2Title;

  /// No description provided for @onboardApiStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Sign in → create new key → copy'**
  String get onboardApiStep2Sub;

  /// No description provided for @onboardApiStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Paste it here'**
  String get onboardApiStep3Title;

  /// No description provided for @onboardApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Your API key'**
  String get onboardApiKeyHint;

  /// No description provided for @onboardApiPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get onboardApiPaste;

  /// No description provided for @onboardApiFreeTierHint.
  ///
  /// In en, this message translates to:
  /// **'Or skip — you get 20 free messages/day'**
  String get onboardApiFreeTierHint;

  /// No description provided for @onboardLevelBubble.
  ///
  /// In en, this message translates to:
  /// **'How much can you say already? It auto-adjusts as we chat.'**
  String get onboardLevelBubble;

  /// No description provided for @onboardLevelHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Where do\n'**
  String get onboardLevelHeadline1;

  /// No description provided for @onboardLevelHeadline2.
  ///
  /// In en, this message translates to:
  /// **'you start'**
  String get onboardLevelHeadline2;

  /// No description provided for @onboardLevelHeadline3.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get onboardLevelHeadline3;

  /// No description provided for @onboardLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get onboardLevelBeginner;

  /// No description provided for @onboardLevelNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get onboardLevelNative;

  /// No description provided for @settingsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsHeaderTitle;

  /// No description provided for @settingsSectionLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get settingsSectionLearning;

  /// No description provided for @settingsSectionAi.
  ///
  /// In en, this message translates to:
  /// **'AI Setup'**
  String get settingsSectionAi;

  /// No description provided for @settingsSectionConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get settingsSectionConversation;

  /// No description provided for @settingsSectionVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get settingsSectionVoice;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsHeroLevelLearner.
  ///
  /// In en, this message translates to:
  /// **'Level {level} Learner'**
  String settingsHeroLevelLearner(int level);

  /// No description provided for @settingsStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get settingsStatStreak;

  /// No description provided for @settingsStatStreakSub.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get settingsStatStreakSub;

  /// No description provided for @settingsStatWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get settingsStatWords;

  /// No description provided for @settingsStatWordsSub.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get settingsStatWordsSub;

  /// No description provided for @settingsStatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get settingsStatToday;

  /// No description provided for @settingsStatTodaySub.
  ///
  /// In en, this message translates to:
  /// **'/ {goal}'**
  String settingsStatTodaySub(int goal);

  /// No description provided for @settingsRowVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get settingsRowVocabulary;

  /// No description provided for @settingsRowVocabularyDetail.
  ///
  /// In en, this message translates to:
  /// **'Saved words'**
  String get settingsRowVocabularyDetail;

  /// No description provided for @settingsRowWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get settingsRowWeeklyReport;

  /// No description provided for @settingsRowWeeklyReportDetail.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get settingsRowWeeklyReportDetail;

  /// No description provided for @settingsRowLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get settingsRowLevel;

  /// No description provided for @settingsRowNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Native language'**
  String get settingsRowNativeLanguage;

  /// No description provided for @settingsRowTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get settingsRowTargetLanguage;

  /// No description provided for @settingsRowProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsRowProvider;

  /// No description provided for @settingsRowModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsRowModel;

  /// No description provided for @settingsRowApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsRowApiKey;

  /// No description provided for @settingsGetFreeKey.
  ///
  /// In en, this message translates to:
  /// **'Get free key at {hint}'**
  String settingsGetFreeKey(String hint);

  /// No description provided for @settingsApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'paste your key…'**
  String get settingsApiKeyHint;

  /// No description provided for @settingsPickerProvider.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get settingsPickerProvider;

  /// No description provided for @settingsPickerModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsPickerModel;

  /// No description provided for @settingsShowTargetText.
  ///
  /// In en, this message translates to:
  /// **'Show {language} text'**
  String settingsShowTargetText(String language);

  /// No description provided for @settingsShowTargetTextSub.
  ///
  /// In en, this message translates to:
  /// **'Display AI response on screen'**
  String get settingsShowTargetTextSub;

  /// No description provided for @settingsShowNativeTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show {language} translation'**
  String settingsShowNativeTranslation(String language);

  /// No description provided for @settingsShowNativeTranslationSub.
  ///
  /// In en, this message translates to:
  /// **'Inline hints in parentheses'**
  String get settingsShowNativeTranslationSub;

  /// No description provided for @settingsSuggestionTiming.
  ///
  /// In en, this message translates to:
  /// **'Suggestion timing'**
  String get settingsSuggestionTiming;

  /// No description provided for @settingsSuggestionImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get settingsSuggestionImmediate;

  /// No description provided for @settingsSuggestionDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get settingsSuggestionDelayed;

  /// No description provided for @settingsReadTargetAloud.
  ///
  /// In en, this message translates to:
  /// **'Read {language} aloud'**
  String settingsReadTargetAloud(String language);

  /// No description provided for @settingsReadTranslationAloud.
  ///
  /// In en, this message translates to:
  /// **'Read translation aloud'**
  String get settingsReadTranslationAloud;

  /// No description provided for @settingsVoiceGender.
  ///
  /// In en, this message translates to:
  /// **'Voice gender'**
  String get settingsVoiceGender;

  /// No description provided for @settingsVoiceFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsVoiceFemale;

  /// No description provided for @settingsVoiceMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsVoiceMale;

  /// No description provided for @settingsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get settingsSpeed;

  /// No description provided for @settingsSpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get settingsSpeedSlow;

  /// No description provided for @settingsSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsSpeedNormal;

  /// No description provided for @settingsSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get settingsSpeedFast;

  /// No description provided for @settingsMicPause.
  ///
  /// In en, this message translates to:
  /// **'Mic pause tolerance'**
  String get settingsMicPause;

  /// No description provided for @settingsMicPauseSub.
  ///
  /// In en, this message translates to:
  /// **'How long you can pause mid-sentence'**
  String get settingsMicPauseSub;

  /// No description provided for @settingsMicPauseQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick 3s'**
  String get settingsMicPauseQuick;

  /// No description provided for @settingsMicPauseNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal 5s'**
  String get settingsMicPauseNormal;

  /// No description provided for @settingsMicPausePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient 8s'**
  String get settingsMicPausePatient;

  /// No description provided for @settingsAutoSendVoice.
  ///
  /// In en, this message translates to:
  /// **'Auto-send voice'**
  String get settingsAutoSendVoice;

  /// No description provided for @settingsAutoSendVoiceSub.
  ///
  /// In en, this message translates to:
  /// **'Off: tap send to confirm what you said'**
  String get settingsAutoSendVoiceSub;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsDailyReminderOn.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String settingsDailyReminderOn(String time);

  /// No description provided for @settingsDailyReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Get nudged to practice'**
  String get settingsDailyReminderOff;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsSendFeedbackDetail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsSendFeedbackDetail;

  /// No description provided for @settingsFeedbackEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get settingsFeedbackEmailFailed;

  /// No description provided for @levelDesc1.
  ///
  /// In en, this message translates to:
  /// **'1 sentence, basic words'**
  String get levelDesc1;

  /// No description provided for @levelDesc2.
  ///
  /// In en, this message translates to:
  /// **'1-2 sentences, everyday words'**
  String get levelDesc2;

  /// No description provided for @levelDesc3.
  ///
  /// In en, this message translates to:
  /// **'2 sentences, simple phrases'**
  String get levelDesc3;

  /// No description provided for @levelDesc4.
  ///
  /// In en, this message translates to:
  /// **'2-3 sentences, common idioms'**
  String get levelDesc4;

  /// No description provided for @levelDesc5.
  ///
  /// In en, this message translates to:
  /// **'2-3 sentences, natural conversation'**
  String get levelDesc5;

  /// No description provided for @levelDesc6.
  ///
  /// In en, this message translates to:
  /// **'3-4 sentences, idioms & phrasal verbs'**
  String get levelDesc6;

  /// No description provided for @levelDesc7.
  ///
  /// In en, this message translates to:
  /// **'3-4 sentences, rich vocabulary'**
  String get levelDesc7;

  /// No description provided for @levelDesc8.
  ///
  /// In en, this message translates to:
  /// **'4-5 sentences, advanced expressions'**
  String get levelDesc8;

  /// No description provided for @levelDesc9.
  ///
  /// In en, this message translates to:
  /// **'4-5 sentences, near-native nuance'**
  String get levelDesc9;

  /// No description provided for @levelDesc10.
  ///
  /// In en, this message translates to:
  /// **'5 sentences, full native level'**
  String get levelDesc10;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Startup error'**
  String get startupError;

  /// No description provided for @startupContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get startupContinueAnyway;

  /// No description provided for @vocabTitle.
  ///
  /// In en, this message translates to:
  /// **'My Vocabulary'**
  String get vocabTitle;

  /// No description provided for @vocabTabAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String vocabTabAll(int count);

  /// No description provided for @vocabTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String vocabTabReview(int count);

  /// No description provided for @vocabCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get vocabCaughtUp;

  /// No description provided for @vocabCaughtUpSub.
  ///
  /// In en, this message translates to:
  /// **'No words to review right now.'**
  String get vocabCaughtUpSub;

  /// No description provided for @vocabListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No words saved yet.\nLong-press text in chat or tap + to add.'**
  String get vocabListEmpty;

  /// No description provided for @vocabAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Word'**
  String get vocabAddTitle;

  /// No description provided for @vocabFieldExpression.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get vocabFieldExpression;

  /// No description provided for @vocabFieldExpressionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. break the ice'**
  String get vocabFieldExpressionHint;

  /// No description provided for @vocabFieldMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get vocabFieldMeaning;

  /// No description provided for @vocabFieldMeaningHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. to start a conversation'**
  String get vocabFieldMeaningHint;

  /// No description provided for @vocabButtonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get vocabButtonAdd;

  /// No description provided for @vocabReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete!'**
  String get vocabReviewComplete;

  /// No description provided for @vocabReviewTapReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get vocabReviewTapReveal;

  /// No description provided for @vocabReviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get vocabReviewAgain;

  /// No description provided for @vocabReviewGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get vocabReviewGotIt;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get reportTitle;

  /// No description provided for @reportSectionDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get reportSectionDaily;

  /// No description provided for @reportSectionTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics Practiced'**
  String get reportSectionTopics;

  /// No description provided for @reportSectionLevels.
  ///
  /// In en, this message translates to:
  /// **'Level Changes'**
  String get reportSectionLevels;

  /// No description provided for @reportNoTopics.
  ///
  /// In en, this message translates to:
  /// **'No topic sessions this week.\nTry the Topic Focus mode!'**
  String get reportNoTopics;

  /// No description provided for @reportNoLevels.
  ///
  /// In en, this message translates to:
  /// **'No level changes this week.'**
  String get reportNoLevels;

  /// No description provided for @reportStatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get reportStatMessages;

  /// No description provided for @reportStatActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get reportStatActiveDays;

  /// No description provided for @reportStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get reportStatStreak;

  /// No description provided for @reportTurns.
  ///
  /// In en, this message translates to:
  /// **'{turns} turns'**
  String reportTurns(int turns);

  /// No description provided for @reportLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String reportLevelLabel(int level);

  /// No description provided for @topicSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Topic'**
  String get topicSheetTitle;

  /// No description provided for @topicTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Topic'**
  String get topicTodayLabel;

  /// No description provided for @topicActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get topicActive;

  /// No description provided for @topicCategoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Life'**
  String get topicCategoryDaily;

  /// No description provided for @topicCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get topicCategoryTravel;

  /// No description provided for @topicCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get topicCategoryFood;

  /// No description provided for @topicCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work & Business'**
  String get topicCategoryWork;

  /// No description provided for @topicCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get topicCategoryShopping;

  /// No description provided for @topicCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get topicCategoryHealth;

  /// No description provided for @topicCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get topicCategorySocial;

  /// No description provided for @topicCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get topicCategoryEntertainment;

  /// No description provided for @missionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missionSheetTitle;

  /// No description provided for @missionDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get missionDifficultyEasy;

  /// No description provided for @missionDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get missionDifficultyMedium;

  /// No description provided for @missionDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get missionDifficultyHard;

  /// No description provided for @missionTurnsNeeded.
  ///
  /// In en, this message translates to:
  /// **'{turns} turns needed'**
  String missionTurnsNeeded(int turns);

  /// No description provided for @pronSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat After Me'**
  String get pronSheetTitle;

  /// No description provided for @pronListenFirst.
  ///
  /// In en, this message translates to:
  /// **'Listen first'**
  String get pronListenFirst;

  /// No description provided for @pronReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic and read the sentence aloud'**
  String get pronReadyHint;

  /// No description provided for @pronListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get pronListening;

  /// No description provided for @pronEvaluating.
  ///
  /// In en, this message translates to:
  /// **'Evaluating your pronunciation...'**
  String get pronEvaluating;

  /// No description provided for @pronTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get pronTryAgain;

  /// No description provided for @pronDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pronDetails;

  /// No description provided for @pronScoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get pronScoreExcellent;

  /// No description provided for @pronScoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good!'**
  String get pronScoreGood;

  /// No description provided for @pronScoreKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing'**
  String get pronScoreKeepPracticing;

  /// No description provided for @pronScoreNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get pronScoreNeedsWork;

  /// No description provided for @pronError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String pronError(String message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
