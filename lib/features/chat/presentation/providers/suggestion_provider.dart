import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/ai/ai_service.dart';

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
  final AiService _aiService;
  final ChatNotifier _chatNotifier;
  Timer? _delayTimer;
  bool _wasAiTyping = false;

  SuggestionNotifier(this._aiService, this._chatNotifier)
      : super(const SuggestionState());

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

    try {
      final suggestions = await _aiService.generateSuggestions(
        conversationHistory: chatState.messages,
        userLevel: chatState.userLevel,
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
  final aiService = ref.watch(aiServiceProvider);
  final chatNotifier = ref.watch(chatProvider.notifier);

  final notifier = SuggestionNotifier(aiService, chatNotifier);

  // chatProvider 상태 변화 감지
  ref.listen(chatProvider, (prev, next) {
    notifier.onChatStateChanged(next);
  });

  return notifier;
});
