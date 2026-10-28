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
  LevelAssessment result;
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
  late _FixedAssessmentAi ai;

  Future<LevelNotifier> notifierWith(LevelAssessment result,
      {int level = 3, int counter = 4}) async {
    SharedPreferences.setMockInitialValues({
      'user_level': level,
      'messages_since_assessment': counter,
    });
    prefs = await SharedPreferences.getInstance();
    recorded = [];
    ai = _FixedAssessmentAi(result);
    return LevelNotifier(
      ai,
      prefs,
      getNativeLanguage: () => AppLanguage.korean,
      getTargetLanguage: () => AppLanguage.englishUS,
      recordLevelChange: (level, reasoning) async =>
          recorded.add((level, reasoning)),
    );
  }

  test('실패한 평가는 레벨을 건드리지 않고 기록도 남기지 않는다', () async {
    final notifier = await notifierWith(const LevelAssessment.failed());
    notifier.onChatStateChanged(_chatWith(4), _chatWith(5));
    await pumpEventQueue();

    expect(ai.calls, 1);
    expect(notifier.state.currentLevel, 3);
    expect(notifier.state.isAssessing, isFalse);
    expect(prefs.getInt('user_level'), 3);
    // 0으로 되돌리지 않고 2메시지 뒤에 다시 본다.
    expect(prefs.getInt('messages_since_assessment'), 3);
    expect(recorded, isEmpty);
  });

  /// 사용자 메시지를 [from]개에서 [to]개까지 하나씩 늘리며 평가 호출이 나간
  /// 시점(사용자 메시지 수)을 모은다.
  Future<List<int>> assessedAt(LevelNotifier notifier, int from, int to) async {
    final at = <int>[];
    for (var n = from + 1; n <= to; n++) {
      final before = ai.calls;
      notifier.onChatStateChanged(_chatWith(n - 1), _chatWith(n));
      await pumpEventQueue();
      if (ai.calls > before) at.add(n);
    }
    return at;
  }

  test('연속 실패는 메시지마다 재평가하지 않고 간격을 정상 주기까지 늘린다', () async {
    final notifier = await notifierWith(const LevelAssessment.failed());

    // 5번째에서 실패 → 2메시지 뒤, 다시 실패 → 4메시지 뒤, 그다음부터는 5메시지마다.
    expect(await assessedAt(notifier, 4, 21), [5, 7, 11, 16, 21]);
    expect(notifier.state.currentLevel, 3);
  });

  test('성공하면 실패 간격이 처음부터 다시 시작한다', () async {
    final notifier = await notifierWith(const LevelAssessment.failed());
    expect(await assessedAt(notifier, 4, 7), [5, 7]);

    ai.result = const LevelAssessment(
        currentLevel: 0, suggestedLevel: 3, reasoning: 'same');
    expect(await assessedAt(notifier, 7, 11), [11]);
    expect(prefs.getInt('messages_since_assessment'), 0);

    ai.result = const LevelAssessment.failed();
    expect(await assessedAt(notifier, 11, 16), [16]);
    expect(prefs.getInt('messages_since_assessment'), 3);
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
