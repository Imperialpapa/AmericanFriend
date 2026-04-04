import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart' show Message, MessageRole;
import 'package:eng_friend/services/ai/prompts/system_prompt.dart';
import 'package:eng_friend/services/local_db/app_database.dart' hide Message;
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';

/// 채팅 상태
class ChatState {
  final List<Message> messages;
  final bool isAiTyping;
  final String currentAiResponse;
  final int userLevel;
  final String? error;
  final String? conversationId;

  const ChatState({
    this.messages = const [],
    this.isAiTyping = false,
    this.currentAiResponse = '',
    this.userLevel = 5,
    this.error,
    this.conversationId,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isAiTyping,
    String? currentAiResponse,
    int? userLevel,
    String? error,
    String? conversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      currentAiResponse: currentAiResponse ?? this.currentAiResponse,
      userLevel: userLevel ?? this.userLevel,
      error: error,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// 채팅 상태 관리 프로바이더
class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationPipeline _pipeline;
  final AppDatabase _db;
  final bool Function() _hasApiKey;
  final bool Function() _showKoreanHint;
  StreamSubscription<PipelineEvent>? _pipelineSubscription;

  ChatNotifier(this._pipeline, this._db, {required bool Function() hasApiKey, required bool Function() showKoreanHint})
      : _hasApiKey = hasApiKey,
        _showKoreanHint = showKoreanHint,
        super(const ChatState());

  /// 기존 대화 불러오기
  Future<void> loadConversation(String conversationId) async {
    final dbMessages = await _db.getMessages(conversationId);
    final messages = dbMessages
        .map((m) => Message(
              id: m.id,
              content: m.content,
              role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
              timestamp: m.timestamp,
              conversationId: conversationId,
            ))
        .toList();

    state = state.copyWith(
      messages: messages,
      conversationId: conversationId,
    );
  }

  /// 새 대화 시작
  Future<void> startNewConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.createConversation(id);
    state = ChatState(conversationId: id);
  }

  /// 텍스트 메시지 전송
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (!_hasApiKey()) {
      state = state.copyWith(
        error: 'API 키를 설정해 주세요 (Settings에서 입력)',
      );
      return;
    }

    // 대화 ID가 없으면 새로 생성
    if (state.conversationId == null) {
      await startNewConversation();
    }

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    // 사용자 메시지 추가
    final userMessage = Message(
      id: msgId,
      content: text,
      role: MessageRole.user,
      timestamp: now,
      conversationId: state.conversationId,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isAiTyping: true,
      currentAiResponse: '',
      error: null,
    );

    // DB에 저장
    await _db.insertMessage(MessagesCompanion.insert(
      id: msgId,
      conversationId: state.conversationId!,
      content: text,
      role: 'user',
      timestamp: now,
    ));

    // 첫 메시지면 대화 제목 업데이트
    if (state.messages.length == 1) {
      final title =
          text.length > 30 ? '${text.substring(0, 30)}...' : text;
      await _db.updateConversationTitle(state.conversationId!, title);
    }

    // 파이프라인 실행
    final eventStream = _pipeline.processTextInput(
      text: text,
      conversationHistory: state.messages,
      systemPrompt: SystemPrompt.build(userLevel: state.userLevel, showKoreanHint: _showKoreanHint()),
      userLevel: state.userLevel,
    );

    _pipelineSubscription?.cancel();
    _pipelineSubscription = eventStream.listen(
      _handlePipelineEvent,
      onError: (e) {
        state = state.copyWith(
          isAiTyping: false,
          error: e.toString(),
        );
      },
    );
  }

  void _handlePipelineEvent(PipelineEvent event) {
    switch (event) {
      case AiSentenceComplete(:final sentence):
        final updated = state.currentAiResponse.isEmpty
            ? sentence
            : '${state.currentAiResponse} $sentence';
        state = state.copyWith(currentAiResponse: updated);

      case AiResponseComplete(:final fullResponse):
        final aiMsgId =
            '${DateTime.now().millisecondsSinceEpoch}_ai';
        final now = DateTime.now();

        final aiMessage = Message(
          id: aiMsgId,
          content: fullResponse,
          role: MessageRole.assistant,
          timestamp: now,
          conversationId: state.conversationId,
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isAiTyping: false,
          currentAiResponse: '',
        );

        // DB에 저장
        if (state.conversationId != null) {
          _db.insertMessage(MessagesCompanion.insert(
            id: aiMsgId,
            conversationId: state.conversationId!,
            content: fullResponse,
            role: 'assistant',
            timestamp: now,
          ));
        }

      case PipelineError(:final failure):
        state = state.copyWith(
          isAiTyping: false,
          error: failure.message,
        );

      case TtsSpeakingStarted():
      case TtsSpeakingDone():
      case SttPartialResult():
      case SttFinalResult():
      case AiTokenReceived():
        break;
    }
  }

  /// 사용자 끼어들기
  Future<void> interrupt() async {
    _pipelineSubscription?.cancel();
    await _pipeline.interrupt();

    if (state.currentAiResponse.isNotEmpty) {
      final aiMsgId =
          '${DateTime.now().millisecondsSinceEpoch}_ai';
      final now = DateTime.now();

      final aiMessage = Message(
        id: aiMsgId,
        content: state.currentAiResponse,
        role: MessageRole.assistant,
        timestamp: now,
        conversationId: state.conversationId,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isAiTyping: false,
        currentAiResponse: '',
      );

      if (state.conversationId != null) {
        _db.insertMessage(MessagesCompanion.insert(
          id: aiMsgId,
          conversationId: state.conversationId!,
          content: state.currentAiResponse,
          role: 'assistant',
          timestamp: now,
        ));
      }
    } else {
      state = state.copyWith(isAiTyping: false);
    }
  }

  void updateLevel(int level) {
    state = state.copyWith(userLevel: level);
  }

  @override
  void dispose() {
    _pipelineSubscription?.cancel();
    super.dispose();
  }
}

/// 채팅 프로바이더
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final pipeline = ref.watch(conversationPipelineProvider);
  final db = ref.watch(appDatabaseProvider);

  return ChatNotifier(
    pipeline,
    db,
    hasApiKey: () {
      final s = ref.read(settingsProvider);
      final key = s.activeApiKey;
      return key.isNotEmpty;
    },
    showKoreanHint: () {
      return ref.read(settingsProvider).showKoreanHint;
    },
  );
});
