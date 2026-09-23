import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart' show Message, MessageRole;
import 'package:eng_friend/services/ai/prompts/system_prompt.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/services/local_db/app_database.dart' hide Message;
import 'package:eng_friend/services/pipeline/conversation_pipeline.dart';
import 'package:eng_friend/services/pipeline/pipeline_event.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/core/error/failures.dart';
import 'package:eng_friend/core/error/redact_secrets.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';

/// 에러의 종류. 문자열 메시지만으로는 쿼터 소진과 네트워크 오류를 구분할 수 없어서,
/// 핸즈프리 같은 자동 재시도 루프가 어떤 실패인지 알 방법이 없었다.
enum ChatErrorKind { quota, noKey, network, freeTierDown, emptyResponse, unknown }

/// 채팅 상태
/// userLevel은 levelProvider에서 직접 읽음 (별도 보관하지 않음).
class ChatState {
  final List<Message> messages;
  final bool isAiTyping;
  final String currentAiResponse;
  final String? error;
  final ChatErrorKind? errorKind;
  final String? conversationId;

  const ChatState({
    this.messages = const [],
    this.isAiTyping = false,
    this.currentAiResponse = '',
    this.error,
    this.errorKind,
    this.conversationId,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isAiTyping,
    String? currentAiResponse,
    String? error,
    ChatErrorKind? errorKind,
    String? conversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      currentAiResponse: currentAiResponse ?? this.currentAiResponse,
      // error/errorKind는 의도적으로 ?? 를 쓰지 않는다 — 매 갱신마다 초기화되어야 함
      error: error,
      errorKind: error == null ? null : errorKind,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// 채팅 상태 관리 프로바이더
class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationPipeline Function() _getPipeline;
  final AppDatabase _db;
  final bool Function() _hasApiKey;
  final bool Function() _showNativeHint;
  final bool Function() _getTargetTtsEnabled;
  final bool Function() _getNativeTtsEnabled;
  final AppLanguage Function() _getNativeLanguage;
  final AppLanguage Function() _getTargetLanguage;
  final int Function() _getUserLevel;
  final String? Function() _getTopicTitle;
  final String? Function() _getTopicSituation;
  final String? Function() _getTopicAiRole;
  StreamSubscription<PipelineEvent>? _pipelineSubscription;

  ChatNotifier(
    this._db, {
    required ConversationPipeline Function() getPipeline,
    required bool Function() hasApiKey,
    required bool Function() showNativeHint,
    required bool Function() getTargetTtsEnabled,
    required bool Function() getNativeTtsEnabled,
    required AppLanguage Function() getNativeLanguage,
    required AppLanguage Function() getTargetLanguage,
    required int Function() getUserLevel,
    required String? Function() getTopicTitle,
    required String? Function() getTopicSituation,
    required String? Function() getTopicAiRole,
  })  : _getPipeline = getPipeline,
        _hasApiKey = hasApiKey,
        _showNativeHint = showNativeHint,
        _getTargetTtsEnabled = getTargetTtsEnabled,
        _getNativeTtsEnabled = getNativeTtsEnabled,
        _getNativeLanguage = getNativeLanguage,
        _getTargetLanguage = getTargetLanguage,
        _getUserLevel = getUserLevel,
        _getTopicTitle = getTopicTitle,
        _getTopicSituation = getTopicSituation,
        _getTopicAiRole = getTopicAiRole,
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
        error: 'Please set your API key in Settings.',
      );
      return;
    }

    // 이전 답변이 아직 스트리밍 중이면 먼저 끊는다(A-07). 안 끊으면 부분 응답이
    // 사라지고, 이전 턴의 TTS가 새 답변 위로 계속 재생된다.
    // interrupt()를 그대로 부르지 않는 건 isAiTyping이 잠깐 false가 되면
    // 제안 칩이 '사용자 차례'로 보고 불필요한 AI 호출을 하기 때문이다.
    Message? interrupted;
    if (state.isAiTyping) {
      interrupted = await _stopActiveTurn();
    } else {
      // 스트리밍(1~3초)이 끝났어도 TTS는 앞 답변을 10~30초 더 읽는다. 새 턴의
      // beginTurn()은 턴 id만 올리고 큐는 그대로 두므로, 여기서 안 끊으면 새 답변이
      // 옛 문장들 뒤에 줄 선다. 핸즈프리는 turnDone(큐가 빈 뒤)에만 보내고 idle은
      // 무시하므로 영향이 없다.
      await _stopTts();
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
      messages: [
        ...state.messages,
        ?interrupted,
        userMessage,
      ],
      isAiTyping: true,
      currentAiResponse: '',
      error: null,
    );

    // DB에 저장. 여기서 던지면 파이프라인이 시작되지 않아 '...'이 영원히 돈다.
    final userRow = MessagesCompanion.insert(
      id: msgId,
      conversationId: state.conversationId!,
      content: text,
      role: 'user',
      timestamp: now,
    );
    await _logDbFailure(() => _db.insertMessage(userRow));

    // 첫 메시지면 대화 제목 업데이트
    if (state.messages.length == 1) {
      final title =
          text.length > 30 ? '${text.substring(0, 30)}...' : text;
      await _logDbFailure(
          () => _db.updateConversationTitle(state.conversationId!, title));
    }

    // 파이프라인 실행 (매번 최신 설정 반영)
    final pipeline = _getPipeline();
    final level = _getUserLevel();
    final eventStream = pipeline.processTextInput(
      text: text,
      conversationHistory: state.messages,
      systemPrompt: SystemPrompt.build(
        userLevel: level,
        nativeLanguage: _getNativeLanguage(),
        targetLanguage: _getTargetLanguage(),
        showNativeHint: _showNativeHint(),
        topicTitle: _getTopicTitle(),
        topicSituation: _getTopicSituation(),
        topicAiRole: _getTopicAiRole(),
      ),
      userLevel: level,
      targetTtsEnabled: _getTargetTtsEnabled(),
      nativeTtsEnabled: _getNativeTtsEnabled(),
    );

    _pipelineSubscription?.cancel();
    _pipelineSubscription = eventStream.listen(
      _handlePipelineEvent,
      onError: (e) {
        state = state.copyWith(
          isAiTyping: false,
          error: redactSecrets(e.toString()),
          errorKind: ChatErrorKind.unknown,
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
          final row = MessagesCompanion.insert(
            id: aiMsgId,
            conversationId: state.conversationId!,
            content: fullResponse,
            role: 'assistant',
            timestamp: now,
          );
          unawaited(_logDbFailure(() => _db.insertMessage(row)));
        }

      case PipelineError(:final failure):
        state = state.copyWith(
          isAiTyping: false,
          error: failure.message,
          errorKind: switch (failure) {
            RateLimitFailure() => ChatErrorKind.quota,
            FreeTierUnavailableFailure(isNetwork: true) => ChatErrorKind.network,
            FreeTierUnavailableFailure() => ChatErrorKind.freeTierDown,
            NetworkFailure() => ChatErrorKind.network,
            EmptyResponseFailure() => ChatErrorKind.emptyResponse,
            _ => ChatErrorKind.unknown,
          },
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
    final partial = await _stopActiveTurn();
    state = state.copyWith(
      messages: partial == null ? null : [...state.messages, partial],
      isAiTyping: false,
      currentAiResponse: '',
    );
  }

  /// 진행 중인 AI 턴을 끊고(스트림 구독 취소 + TTS 정지), 그때까지 받은 부분
  /// 응답을 assistant 메시지로 확정해 DB에 남긴다. 상태 반영은 호출자 몫이다.
  /// 부분 응답이 비어 있으면 null — 빈 assistant 행을 남기지 않는다(D-05).
  Future<Message?> _stopActiveTurn() async {
    _pipelineSubscription?.cancel();
    _pipelineSubscription = null;
    // 구독을 끊었으니 더 바뀌지 않는다. state를 비우기 전에 잡아 두어야
    // 화면과 DB에 같은 내용이 들어간다(예전엔 비운 뒤에 읽어 DB에 빈 문자열이 갔다).
    final partial = state.currentAiResponse;

    await _stopTts();

    if (partial.trim().isEmpty) return null;

    final aiMsgId = '${DateTime.now().millisecondsSinceEpoch}_ai';
    final now = DateTime.now();
    final conversationId = state.conversationId;
    if (conversationId != null) {
      final row = MessagesCompanion.insert(
        id: aiMsgId,
        conversationId: conversationId,
        content: partial,
        role: 'assistant',
        timestamp: now,
      );
      unawaited(_logDbFailure(() => _db.insertMessage(row)));
    }
    return Message(
      id: aiMsgId,
      content: partial,
      role: MessageRole.assistant,
      timestamp: now,
      conversationId: conversationId,
    );
  }

  /// TTS 재생을 멈추고 대기 중인 문장을 버린다.
  Future<void> _stopTts() async {
    try {
      await _getPipeline().interrupt();
    } catch (e) {
      // TTS 정지 실패로 끼어들기·새 전송이 막히면 안 된다.
      debugPrint('[Chat] pipeline interrupt failed: $e');
    }
  }

  /// 대화 기록 저장은 화면 흐름의 부수효과다. 실패를 그대로 던지면 기다리지 않는
  /// 호출에선 처리되지 않은 예외가 되고, 기다리는 호출에선 전송이 중간에 멈춘다.
  Future<void> _logDbFailure(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('[Chat] DB write failed: $e');
    }
  }

  @override
  void dispose() {
    _pipelineSubscription?.cancel();
    super.dispose();
  }
}

/// 채팅 프로바이더
final StateNotifierProvider<ChatNotifier, ChatState> chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final db = ref.read(appDatabaseProvider);

  return ChatNotifier(
    db,
    getPipeline: () => ref.read(conversationPipelineProvider),
    hasApiKey: () {
      final s = ref.read(settingsProvider);
      final key = s.activeApiKey;
      return key.isNotEmpty;
    },
    showNativeHint: () {
      return ref.read(settingsProvider).showNativeHint;
    },
    getTargetTtsEnabled: () {
      return ref.read(settingsProvider).targetTtsEnabled;
    },
    getNativeTtsEnabled: () {
      return ref.read(settingsProvider).nativeTtsEnabled;
    },
    getNativeLanguage: () {
      return ref.read(settingsProvider).nativeLanguage;
    },
    getTargetLanguage: () {
      return ref.read(settingsProvider).targetLanguage;
    },
    getUserLevel: () {
      // SharedPreferences에서 직접 읽어 levelProvider와의 순환 의존성 회피.
      // levelProvider는 chatProvider를 listen하므로 ref.read(levelProvider)는
      // CircularDependencyError를 일으킴. 두 provider 모두 'user_level' 키에
      // 저장하므로 prefs를 single source of truth로 사용.
      final prefs = ref.read(sharedPreferencesProvider);
      return prefs.getInt('user_level') ?? LevelConstants.defaultLevel;
    },
    getTopicTitle: () {
      final topic = ref.read(topicProvider).activeTopic;
      return topic?.title;
    },
    getTopicSituation: () {
      final topic = ref.read(topicProvider).activeTopic;
      return topic?.situation;
    },
    getTopicAiRole: () {
      final topic = ref.read(topicProvider).activeTopic;
      return topic?.aiRole;
    },
  );
});
