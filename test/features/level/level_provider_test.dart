import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';

class _FixedAssessmentAi implements AiService {
  final LevelAssessment result;
  int calls = 0;
  _FixedAssessmentAi(this.result);

  @override
  Future<LevelAssessment> assessLevel({
    required List<Message> recentMessages,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
  }) async {
    calls++;
    return result;
  }

  @override
  Stream<String> streamMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) =>
      throw UnimplementedError();

  @override
  Future<PronunciationResult> evaluatePronunciation({required String prompt}) =>
      throw UnimplementedError();

  @override
  Future<List<Suggestion>> generateSuggestions({
    required List<Message> conversationHistory,
    required int userLevel,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
    int count = 2,
    String? lastAiMessage,
  }) =>
      throw UnimplementedError();
}

ChatState _chatWith(int userMessages) => ChatState(messages: [
      for (var i = 0; i < userMessages; i++)
        Message(
          id: '$i',
          content: 'message $i',
          role: MessageRole.user,
          timestamp: DateTime(2026),
        ),
    ]);

void main() {
  late SharedPreferences prefs;
  late List<(int, String)> recorded;

  Future<LevelNotifier> notifierWith(LevelAssessment result,
      {int level = 3, int counter = 4}) async {
    SharedPreferences.setMockInitialValues({
      'user_level': level,
      'messages_since_assessment': counter,
    });
    prefs = await SharedPreferences.getInstance();
    recorded = [];
    return LevelNotifier(
      _FixedAssessmentAi(result),
      prefs,
      getNativeLanguage: () => AppLanguage.korean,
      getTargetLanguage: () => AppLanguage.englishUS,
      recordLevelChange: (level, reasoning) async =>
          recorded.add((level, reasoning)),
    );
  }

  test('실패한 평가는 레벨·카운터를 건드리지 않고 기록도 남기지 않는다', () async {
    final notifier = await notifierWith(const LevelAssessment.failed());
    notifier.onChatStateChanged(_chatWith(4), _chatWith(5));
    await pumpEventQueue();

    expect(notifier.state.currentLevel, 3);
    expect(notifier.state.isAssessing, isFalse);
    expect(prefs.getInt('user_level'), 3);
    expect(prefs.getInt('messages_since_assessment'), 5);
    expect(recorded, isEmpty);
  });

  test('레벨이 바뀌면 한 단계만 움직이고 이력을 한 번 남긴다', () async {
    final notifier = await notifierWith(const LevelAssessment(
        currentLevel: 0, suggestedLevel: 8, reasoning: 'fluent'));
    notifier.onChatStateChanged(_chatWith(4), _chatWith(5));
    await pumpEventQueue();

    expect(notifier.state.currentLevel, 4);
    expect(prefs.getInt('user_level'), 4);
    expect(prefs.getInt('messages_since_assessment'), 0);
    expect(recorded, [(4, 'fluent')]);
  });

  test('레벨이 그대로면 이력을 남기지 않는다', () async {
    final notifier = await notifierWith(const LevelAssessment(
        currentLevel: 0, suggestedLevel: 3, reasoning: 'same'));
    notifier.onChatStateChanged(_chatWith(4), _chatWith(5));
    await pumpEventQueue();

    expect(notifier.state.currentLevel, 3);
    expect(prefs.getInt('messages_since_assessment'), 0);
    expect(recorded, isEmpty);
  });
}
