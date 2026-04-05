import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/level/domain/entities/level_assessment.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/ai/ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';

const _levelKey = 'user_level';
const _messageCountKey = 'messages_since_assessment';

class LevelState {
  final int currentLevel;
  final String levelName;
  final bool isAssessing;
  final LevelAssessment? lastAssessment;

  const LevelState({
    this.currentLevel = LevelConstants.defaultLevel,
    this.levelName = 'Intermediate',
    this.isAssessing = false,
    this.lastAssessment,
  });

  LevelState copyWith({
    int? currentLevel,
    String? levelName,
    bool? isAssessing,
    LevelAssessment? lastAssessment,
  }) {
    return LevelState(
      currentLevel: currentLevel ?? this.currentLevel,
      levelName: levelName ?? this.levelName,
      isAssessing: isAssessing ?? this.isAssessing,
      lastAssessment: lastAssessment ?? this.lastAssessment,
    );
  }
}

class LevelNotifier extends StateNotifier<LevelState> {
  final AiService _aiService;
  final SharedPreferences _prefs;
  final AppLanguage Function() _getNativeLanguage;
  final AppLanguage Function() _getTargetLanguage;
  int _messagesSinceAssessment = 0;

  LevelNotifier(
    this._aiService,
    this._prefs, {
    required AppLanguage Function() getNativeLanguage,
    required AppLanguage Function() getTargetLanguage,
  })  : _getNativeLanguage = getNativeLanguage,
        _getTargetLanguage = getTargetLanguage,
        super(const LevelState()) {
    _load();
  }

  void _load() {
    final level = _prefs.getInt(_levelKey) ?? LevelConstants.defaultLevel;
    _messagesSinceAssessment = _prefs.getInt(_messageCountKey) ?? 0;
    state = state.copyWith(
      currentLevel: level,
      levelName: LevelConstants.levelNames[level],
    );
  }

  /// 채팅 상태 변화 감지 — 사용자 메시지가 추가될 때마다 카운트
  void onChatStateChanged(ChatState prev, ChatState next) {
    // 새 사용자 메시지가 추가되었는지 확인
    final prevUserCount =
        prev.messages.where((m) => m.role == MessageRole.user).length;
    final nextUserCount =
        next.messages.where((m) => m.role == MessageRole.user).length;

    if (nextUserCount > prevUserCount) {
      _messagesSinceAssessment++;
      _prefs.setInt(_messageCountKey, _messagesSinceAssessment);

      if (_messagesSinceAssessment >= LevelConstants.messagesPerAssessment) {
        _assess(next.messages);
      }
    }
  }

  Future<void> _assess(List<Message> messages) async {
    if (state.isAssessing) return;
    state = state.copyWith(isAssessing: true);

    try {
      // 최근 메시지만 전송
      final recent = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;

      final assessment = await _aiService.assessLevel(
        recentMessages: recent,
        nativeLanguage: _getNativeLanguage(),
        targetLanguage: _getTargetLanguage(),
      );

      // 급격한 변동 방지: 최대 1단계 변경
      final diff = assessment.suggestedLevel - state.currentLevel;
      final clampedDiff = diff.clamp(
          -LevelConstants.maxLevelChange, LevelConstants.maxLevelChange);
      final newLevel = (state.currentLevel + clampedDiff)
          .clamp(LevelConstants.minLevel, LevelConstants.maxLevel);

      _messagesSinceAssessment = 0;
      await _prefs.setInt(_levelKey, newLevel);
      await _prefs.setInt(_messageCountKey, 0);

      state = state.copyWith(
        currentLevel: newLevel,
        levelName: LevelConstants.levelNames[newLevel],
        isAssessing: false,
        lastAssessment: assessment,
      );
    } catch (_) {
      state = state.copyWith(isAssessing: false);
    }
  }

  /// 수동 레벨 설정 (온보딩용)
  Future<void> setLevel(int level) async {
    final clamped =
        level.clamp(LevelConstants.minLevel, LevelConstants.maxLevel);
    await _prefs.setInt(_levelKey, clamped);
    state = state.copyWith(
      currentLevel: clamped,
      levelName: LevelConstants.levelNames[clamped],
    );
  }
}

final levelProvider = StateNotifierProvider<LevelNotifier, LevelState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = LevelNotifier(
    aiService,
    prefs,
    getNativeLanguage: () => ref.read(settingsProvider).nativeLanguage,
    getTargetLanguage: () => ref.read(settingsProvider).targetLanguage,
  );

  // chatProvider 상태 변화 감지
  ref.listen(chatProvider, (prev, next) {
    if (prev != null) {
      notifier.onChatStateChanged(prev, next);
    }
  });

  return notifier;
});
