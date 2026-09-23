import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart' show MessageRole;
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';

class SuggestionState {
  final List<Suggestion> suggestions;
  final bool isLoading;

  const SuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
  });

  SuggestionState copyWith({
    List<Suggestion>? suggestions,
    bool? isLoading,
  }) {
    return SuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SuggestionNotifier extends StateNotifier<SuggestionState> {
  final AiService Function() _getAiService;
  final ChatNotifier _chatNotifier;
  final AppLanguage Function() _getNativeLanguage;
  final AppLanguage Function() _getTargetLanguage;
  final int Function() _getDelaySec;
  final int Function() _getUserLevel;
  Timer? _delayTimer;
  bool _wasAiTyping = false;

  SuggestionNotifier(
    this._chatNotifier, {
    required AiService Function() getAiService,
    required AppLanguage Function() getNativeLanguage,
    required AppLanguage Function() getTargetLanguage,
    required int Function() getDelaySec,
    required int Function() getUserLevel,
  })  : _getAiService = getAiService,
        _getNativeLanguage = getNativeLanguage,
        _getTargetLanguage = getTargetLanguage,
        _getDelaySec = getDelaySec,
        _getUserLevel = getUserLevel,
        super(const SuggestionState());

  /// chatProvider의 상태 변화를 감지하여 호출
  void onChatStateChanged(ChatState chatState) {
    // AI가 타이핑을 끝냈을 때 = 사용자 차례
    if (_wasAiTyping && !chatState.isAiTyping && chatState.error == null) {
      _triggerSuggestion(chatState);
    }
    _wasAiTyping = chatState.isAiTyping;
  }

  void _triggerSuggestion(ChatState chatState) {
    _delayTimer?.cancel();
    state = state.copyWith(suggestions: []);

    final delay = _getDelaySec();
    if (delay <= 0) {
      _fetchSuggestions(chatState);
    } else {
      _delayTimer = Timer(Duration(seconds: delay), () {
        _fetchSuggestions(chatState);
      });
    }
  }

  Future<void> _fetchSuggestions(ChatState chatState) async {
    state = state.copyWith(isLoading: true);

    // 마지막 AI 메시지 추출
    String? lastAiMsg;
    for (int i = chatState.messages.length - 1; i >= 0; i--) {
      if (chatState.messages[i].role == MessageRole.assistant) {
        lastAiMsg = chatState.messages[i].content;
        break;
      }
    }

    try {
      final suggestions = await _getAiService().generateSuggestions(
        conversationHistory: chatState.messages,
        userLevel: _getUserLevel(),
        nativeLanguage: _getNativeLanguage(),
        targetLanguage: _getTargetLanguage(),
        lastAiMessage: lastAiMsg,
      );
      state = state.copyWith(suggestions: suggestions, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 제안을 선택했을 때
  void selectSuggestion(Suggestion suggestion) {
    _delayTimer?.cancel();
    state = state.copyWith(suggestions: []);
    _chatNotifier.sendMessage(suggestion.text);
  }

  /// 사용자가 직접 타이핑 시작 → 제안 취소
  void cancelSuggestion() {
    _delayTimer?.cancel();
    state = state.copyWith(suggestions: [], isLoading: false);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }
}

final suggestionProvider =
    StateNotifierProvider<SuggestionNotifier, SuggestionState>((ref) {
  final chatNotifier = ref.watch(chatProvider.notifier);

  final notifier = SuggestionNotifier(
    chatNotifier,
    getAiService: () => ref.read(aiServiceProvider),
    getNativeLanguage: () => ref.read(settingsProvider).nativeLanguage,
    getTargetLanguage: () => ref.read(settingsProvider).targetLanguage,
    getDelaySec: () => ref.read(settingsProvider).suggestionDelaySec,
    getUserLevel: () {
      // levelProvider 직접 read 시 chatProvider와의 순환 의존성 위험.
      // SharedPreferences를 single source of truth로 사용 (chat_provider와 동일 패턴).
      final prefs = ref.read(sharedPreferencesProvider);
      return prefs.getInt('user_level') ?? LevelConstants.defaultLevel;
    },
  );

  // chatProvider 상태 변화 감지
  ref.listen<ChatState>(chatProvider, (prev, next) {
    notifier.onChatStateChanged(next);
  });

  return notifier;
});
