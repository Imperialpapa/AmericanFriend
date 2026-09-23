import 'package:flutter/foundation.dart' show debugPrint;
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
  final Future<void> Function(int level, String reasoning) _recordLevelChange;
  int _messagesSinceAssessment = 0;
  // 메모리에만 둔다 — 재시작 후엔 짧은 간격부터 다시 시작해도 손해가 작다.
  int _consecutiveFailures = 0;

  /// 실패 1회마다 다음 재평가까지 늘어나는 메시지 수.
  static const _retryStep = 2;

  LevelNotifier(
    this._aiService,
    this._prefs, {
    required AppLanguage Function() getNativeLanguage,
    required AppLanguage Function() getTargetLanguage,
    required Future<void> Function(int level, String reasoning)
        recordLevelChange,
  })  : _getNativeLanguage = getNativeLanguage,
        _getTargetLanguage = getTargetLanguage,
        _recordLevelChange = recordLevelChange,
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

      // 실패는 레벨을 건드리지 않는다. 예전엔 실패가 suggestedLevel 5로 위장돼
      // 초급자가 끌려 올라갔다(tobe A-06).
      if (assessment.isFailure) {
        debugPrint('[Level] assessment failed: ${assessment.reasoning}');
        await _backOffAfterFailure();
        return;
      }

      // 급격한 변동 방지: 최대 1단계 변경
      final diff = assessment.suggestedLevel - state.currentLevel;
      final clampedDiff = diff.clamp(
          -LevelConstants.maxLevelChange, LevelConstants.maxLevelChange);
      final newLevel = (state.currentLevel + clampedDiff)
          .clamp(LevelConstants.minLevel, LevelConstants.maxLevel);
      final changed = newLevel != state.currentLevel;

      _consecutiveFailures = 0;
      _messagesSinceAssessment = 0;
      await _prefs.setInt(_levelKey, newLevel);
      await _prefs.setInt(_messageCountKey, 0);

      state = state.copyWith(
        currentLevel: newLevel,
        levelName: LevelConstants.levelNames[newLevel],
        isAssessing: false,
        lastAssessment: assessment,
      );

      // 주간 리포트 Level Changes의 입력. 무변동까지 넣으면 리포트가 잡음이 된다.
      if (changed) await _recordLevelChange(newLevel, assessment.reasoning);
    } catch (_) {
      state = state.copyWith(isAssessing: false);
    }
  }

  /// 카운터를 그대로 두면 이후 사용자 메시지마다 재평가가 나간다(분석 T14의
  /// '재시도 폭주'). BYOK는 호출마다 과금, 무료 티어는 하루 20회에서 1회씩 깎인다.
  /// 일시 장애는 곧 다시 보도록 2 → 4메시지 뒤로 미루고, 계속 실패하면 정상 주기
  /// (messagesPerAssessment)보다 자주 부르지 않는다.
  Future<void> _backOffAfterFailure() async {
    _consecutiveFailures++;
    final wait = (_retryStep * _consecutiveFailures)
        .clamp(1, LevelConstants.messagesPerAssessment);
    _messagesSinceAssessment = LevelConstants.messagesPerAssessment - wait;
    state = state.copyWith(isAssessing: false);
    await _prefs.setInt(_messageCountKey, _messagesSinceAssessment);
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

final StateNotifierProvider<LevelNotifier, LevelState> levelProvider =
    StateNotifierProvider<LevelNotifier, LevelState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = LevelNotifier(
    aiService,
    prefs,
    getNativeLanguage: () => ref.read(settingsProvider).nativeLanguage,
    getTargetLanguage: () => ref.read(settingsProvider).targetLanguage,
    // appDatabaseProvider는 leaf라 순환 의존 위험이 없다(BUG #5).
    recordLevelChange: (level, reasoning) =>
        ref.read(appDatabaseProvider).insertLevelRecord(level, reasoning),
  );

  // chatProvider 상태 변화 감지
  ref.listen<ChatState>(chatProvider, (prev, next) {
    if (prev != null) {
      notifier.onChatStateChanged(prev, next);
    }
  });

  return notifier;
});
