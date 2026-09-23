import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/domain/entities/pronunciation_result.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/services/local_db/app_database.dart'
    show AppDatabase, Conversation, MessagesCompanion;
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

/// 턴마다 토큰 스트림을 테스트가 직접 흘린다.
class _ControlledAi implements AiService {
  final turns = <StreamController<String>>[];

  @override
  Stream<String> streamMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) {
    final c = StreamController<String>();
    turns.add(c);
    return c.stream;
  }

  @override
  Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String systemPrompt,
    required int userLevel,
  }) =>
      throw UnimplementedError();

  @override
  Future<LevelAssessment> assessLevel({
    required List<Message> recentMessages,
    required AppLanguage nativeLanguage,
    required AppLanguage targetLanguage,
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

class _FakeTtsQueue implements TtsQueue {
  int _turn = 0;
  int interrupts = 0;

  @override
  int beginTurn() => ++_turn;

  @override
  void markTurnEnd(int turnId) {}

  @override
  Future<void> enqueue(String sentence) async {}

  @override
  Future<void> interrupt() async {
    interrupts++;
    _turn++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDb implements AppDatabase {
  final rows = <MessagesCompanion>[];
  bool failWrites = false;

  List<String> contentsOf(String role) => rows
      .where((r) => r.role.value == role)
      .map((r) => r.content.value)
      .toList();

  @override
  Future<Conversation> createConversation(String id) async => Conversation(
        id: id,
        title: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  @override
  Future<void> insertMessage(MessagesCompanion message) async {
    if (failWrites) throw StateError('disk full');
    rows.add(message);
  }

  @override
  Future<void> updateConversationTitle(String id, String title) async {
    if (failWrites) throw StateError('disk full');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ControlledAi ai;
  late _FakeTtsQueue tts;
  late _FakeDb db;
  late ChatNotifier chat;

  setUp(() {
    ai = _ControlledAi();
    tts = _FakeTtsQueue();
    db = _FakeDb();
    final pipeline = ConversationPipeline(aiService: ai, ttsQueue: tts);
    chat = ChatNotifier(
      db,
      getPipeline: () => pipeline,
      hasApiKey: () => true,
      showNativeHint: () => false,
      getTargetTtsEnabled: () => false,
      getNativeTtsEnabled: () => false,
      getNativeLanguage: () => AppLanguage.korean,
      getTargetLanguage: () => AppLanguage.englishUS,
      getUserLevel: () => 3,
      getTopicTitle: () => null,
      getTopicSituation: () => null,
      getTopicAiRole: () => null,
    );
  });

  tearDown(() async {
    chat.dispose();
    for (final c in ai.turns) {
      unawaited(c.close());
    }
  });

  List<(MessageRole, String)> transcript() =>
      chat.state.messages.map((m) => (m.role, m.content)).toList();

  test('스트리밍 중 새 전송: 부분 응답을 남기고 TTS를 멈춘 뒤 새 턴을 연다 (A-07)',
      () async {
    await chat.sendMessage('first');
    await pumpEventQueue();
    ai.turns[0].add('Hello there. How are ');
    await pumpEventQueue();
    expect(chat.state.currentAiResponse, 'Hello there.');

    await chat.sendMessage('second');
    await pumpEventQueue();

    expect(transcript(), [
      (MessageRole.user, 'first'),
      (MessageRole.assistant, 'Hello there.'),
      (MessageRole.user, 'second'),
    ]);
    expect(chat.state.isAiTyping, isTrue);
    expect(chat.state.currentAiResponse, '');
    expect(tts.interrupts, 1);
    expect(db.contentsOf('assistant'), ['Hello there.']);
    expect(ai.turns, hasLength(2));

    // 끊긴 첫 턴의 토큰이 뒤늦게 와도 새 답변에 섞이지 않는다.
    ai.turns[0].add('you? ');
    ai.turns[1].add('Second answer. ');
    await pumpEventQueue();
    expect(chat.state.currentAiResponse, 'Second answer.');
  });

  test('끼어들기: 화면과 DB에 같은 부분 응답이 들어간다 (D-05)', () async {
    await chat.sendMessage('first');
    await pumpEventQueue();
    ai.turns[0].add('Partial answer. And ');
    await pumpEventQueue();

    await chat.interrupt();

    expect(transcript().last, (MessageRole.assistant, 'Partial answer.'));
    expect(db.contentsOf('assistant'), ['Partial answer.']);
    expect(chat.state.isAiTyping, isFalse);
  });

  test('끼어들기: 부분 응답이 없으면 빈 assistant 행을 남기지 않는다 (D-05)',
      () async {
    await chat.sendMessage('first');
    await pumpEventQueue();

    await chat.interrupt();

    expect(transcript(), [(MessageRole.user, 'first')]);
    expect(db.contentsOf('assistant'), isEmpty);
    expect(chat.state.isAiTyping, isFalse);
  });

  test('DB 쓰기가 실패해도 전송이 멈추지 않는다', () async {
    db.failWrites = true;

    await chat.sendMessage('first');
    await pumpEventQueue();
    expect(ai.turns, hasLength(1));

    ai.turns[0].add('Fine. ');
    await ai.turns[0].close();
    await pumpEventQueue();

    expect(transcript(), [
      (MessageRole.user, 'first'),
      (MessageRole.assistant, 'Fine.'),
    ]);
    expect(chat.state.isAiTyping, isFalse);
  });
}
