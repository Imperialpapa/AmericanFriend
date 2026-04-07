import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart' show MessageRole;
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';

enum SuggestionMode { immediate, delayed }

class SuggestionState {
  final List<Suggestion> suggestions;
  final bool isLoading;
  final SuggestionMode mode;
  final int delaySec;

  const SuggestionState({
    this.suggestions = const [],
    this.isLoading = false,
    this.mode = SuggestionMode.delayed,
    this.delaySec = 5,
  });

  SuggestionState copyWith({
    List<Suggestion>? suggestions,
    bool? isLoading,
    SuggestionMode? mode,
    int? delaySec,
  }) {
    return SuggestionState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      delaySec: delaySec ?? this.delaySec,
    );
  }
}

class SuggestionNotifier extends StateNotifier<SuggestionState> {
  final AiService Function() _getAiService;
  final ChatNotifier _chatNotifier;
  final AppLanguage Function() _getNativeLanguage;
  final AppLanguage Function() _getTargetLanguage;
  Timer? _delayTimer;
  bool _wasAiTyping = false;

  SuggestionNotifier(
    this._chatNotifier, {
    required AiService Function() getAiService,
    required AppLanguage Function() getNativeLanguage,
    required AppLanguage Function() getTargetLanguage,
  })  : _getAiService = getAiService,
        _getNativeLanguage = getNativeLanguage,
        _getTargetLanguage = getTargetLanguage,
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

    if (state.mode == SuggestionMode.immediate) {
      _fetchSuggestions(chatState);
    } else {
      _delayTimer = Timer(Duration(seconds: state.delaySec), () {
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
        userLevel: chatState.userLevel,
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

  void setMode(SuggestionMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setDelay(int seconds) {
    state = state.copyWith(delaySec: seconds);
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
  );

  // chatProvider 상태 변화 감지
  ref.listen(chatProvider, (prev, next) {
    notifier.onChatStateChanged(next);
  });

  return notifier;
});
