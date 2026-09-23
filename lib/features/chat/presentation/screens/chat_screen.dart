import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';
import 'package:eng_friend/core/widgets/app_notice_banner.dart';
import 'package:eng_friend/core/widgets/banner_ad_widget.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/chat/presentation/widgets/chat_header.dart';
import 'package:eng_friend/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:eng_friend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:eng_friend/features/chat/presentation/widgets/mission_strip.dart';
import 'package:eng_friend/features/chat/presentation/widgets/suggestion_chips.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/settings/presentation/screens/settings_screen.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

/// 메인 채팅 화면 — Modern Sage redesign.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  /// 핀치 제스처 시작 시점의 chatFontScale. null이면 제스처 비활성.
  double? _scaleStartValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(voiceProvider.notifier).initialize();
      if (!mounted) return;
      // 사용자가 이전에 핸즈프리를 켜뒀으면 채팅 진입과 동시에 루프 시작
      if (ref.read(settingsProvider).handsFreeEnabled) {
        await ref.read(voiceProvider.notifier).startHandsFree();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- 두 손가락 핀치로 메시지 폰트 크기 조절 ----
  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _scaleStartValue = ref.read(settingsProvider).chatFontScale;
    } else {
      _scaleStartValue = null;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final start = _scaleStartValue;
    if (start == null || details.pointerCount < 2) return;
    final newScale = start * details.scale;
    ref
        .read(settingsProvider.notifier)
        .setChatFontScale(newScale, persist: false);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_scaleStartValue == null) return;
    _scaleStartValue = null;
    // 마지막 값을 디스크에 저장
    final cur = ref.read(settingsProvider).chatFontScale;
    ref.read(settingsProvider.notifier).setChatFontScale(cur, persist: true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final chatState = ref.watch(chatProvider);
    final l = AppLocalizations.of(context);

    // streak 목표 달성 축하
    ref.listen(streakProvider, (prev, next) {
      if (next.justReachedGoal) {
        ref.read(streakProvider.notifier).clearJustReachedGoal();
        _showCelebrationSnack(
          context,
          icon: Icons.local_fire_department,
          color: palette.mustard,
          text: l.chatStreakGoalReached(next.currentStreak),
        );
      }
    });

    // 미션 완료 축하
    ref.listen(missionProvider, (prev, next) {
      if (next.justCompleted) {
        ref.read(missionProvider.notifier).clearJustCompleted();
        _showCelebrationSnack(
          context,
          icon: Icons.emoji_events,
          color: palette.mustard,
          text: l.chatMissionComplete(next.starsJustEarned),
        );
      }
    });

    // 설정 화면에서 핸즈프리를 켜고 돌아온 경우 즉시 반영.
    // (채팅 화면 initState는 이미 지나갔으므로 자동 시작 경로를 못 탄다)
    ref.listen(settingsProvider.select((s) => s.handsFreeEnabled), (prev, next) {
      if (prev == next) return;
      final notifier = ref.read(voiceProvider.notifier);
      final active = ref.read(voiceProvider).handsFreeActive;
      // 입력바 토글이 이미 상태를 바꾼 뒤 설정을 저장하는 경로와 중복 실행되지 않도록
      if (next && !active) notifier.startHandsFree();
      if (!next && active) notifier.stopHandsFree();
    });

    // 핸즈프리 오류/자동종료 안내
    ref.listen(voiceProvider.select((s) => s.voiceError), (prev, next) {
      if (next == null || next == prev) return;
      final message = switch (next) {
        'stt_unavailable' => l.handsFreeSttUnavailable,
        'hands_free_idle' => l.handsFreeStoppedIdle,
        'hands_free_quota' => l.handsFreeStoppedQuota,
        'hands_free_error' => l.handsFreeStoppedError,
        _ => next,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          // 마이크 권한 문제는 앱 안에서 못 고친다 — OS 설정으로 보내준다.
          action: next == 'stt_unavailable'
              ? SnackBarAction(
                  label: l.handsFreeOpenSettings,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      ref.read(voiceProvider.notifier).clearVoiceError();
    });

    // 메시지 변경 시 자동 스크롤
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.currentAiResponse != next.currentAiResponse) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        children: [
          const ChatHeader(),

          // 서버 공지 / 업데이트 안내 (제공자 장애 등을 앱 배포 없이 알리는 통로)
          const AppNoticeBanner(),

          // 에러 표시
          if (chatState.error != null)
            _buildErrorBanner(context, chatState.error!, chatState.errorKind),

          // 메시지 영역 + Mission Strip — 두 손가락 핀치로 폰트 크기 조절
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: <Type, GestureRecognizerFactory>{
                ScaleGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                  (ScaleGestureRecognizer instance) {
                    instance
                      ..onStart = _onScaleStart
                      ..onUpdate = _onScaleUpdate
                      ..onEnd = _onScaleEnd;
                  },
                ),
              },
              child: chatState.messages.isEmpty && !chatState.isAiTyping
                  ? _buildWelcomeMessage()
                  : Column(
                      children: [
                        const MissionStrip(),
                        Expanded(child: _buildMessageList(chatState)),
                      ],
                    ),
            ),
          ),

          // 입력 바 + 배너 광고
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatInputBar(
                  onSendText: (text) {
                    ref.read(chatProvider.notifier).sendMessage(text);
                    ref.read(streakProvider.notifier).recordMessage();
                    ref.read(topicProvider.notifier).recordTurn();
                    ref.read(missionProvider.notifier).recordTurn();
                  },
                ),
                const BannerAdWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 사용자에게는 사람 말로 된 안내를, 원문은 "복사" 버튼으로만 넘긴다.
  /// (이전엔 Dio 내부 예외 문자열이 그대로 화면에 덤프되어, 사용자가 자기 폰 문제인지
  ///  네트워크 문제인지 앱이 망가진 건지 구분할 수 없었다.)
  Widget _buildErrorBanner(
    BuildContext context,
    String error,
    ChatErrorKind? kind,
  ) {
    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    final message = switch (kind) {
      ChatErrorKind.freeTierDown => l.chatErrorFreeTierDown,
      ChatErrorKind.quota => l.chatErrorQuota,
      ChatErrorKind.network => l.chatErrorNetwork,
      ChatErrorKind.noKey => l.chatErrorNoKey,
      _ => l.chatErrorUnknown,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: palette.coral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: KFTypography.meta(color: palette.ink),
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: error));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.commonCopied)),
              );
            },
            child: Text(l.commonCopy),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Text(l.chatErrorGoToSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    final hasStreaming =
        chatState.isAiTyping || chatState.currentAiResponse.isNotEmpty;
    final baseCount = chatState.messages.length + (hasStreaming ? 1 : 0);
    final itemCount = baseCount + 1; // +1 for suggestion chips

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: KFSpacing.x2, bottom: KFSpacing.x2),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == baseCount) {
          return const SuggestionChips();
        }

        // Streaming AI response
        if (index == chatState.messages.length && hasStreaming) {
          return MessageBubble(
            content: chatState.currentAiResponse.isEmpty
                ? '...'
                : chatState.currentAiResponse,
            isUser: false,
            isTyping: chatState.currentAiResponse.isEmpty,
            initialDrawerOpen: false,
          );
        }

        final message = chatState.messages[index];
        final isUser = message.role == MessageRole.user;
        final showAvatar = !isUser && _isFirstInAiGroup(chatState, index);
        final isLastAi = !isUser &&
            !hasStreaming &&
            index == chatState.messages.length - 1;

        return MessageBubble(
          content: message.content,
          isUser: isUser,
          initialDrawerOpen: isLastAi,
          showAvatar: showAvatar,
        );
      },
    );
  }

  bool _isFirstInAiGroup(ChatState chatState, int index) {
    if (index == 0) return true;
    final prev = chatState.messages[index - 1];
    return prev.role == MessageRole.user;
  }

  Widget _buildWelcomeMessage() {
    final palette = KFPalette.of(context);
    final settings = ref.watch(settingsProvider);
    final hasApiKey = settings.hasWorkingCredentials;
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KFSpacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: KFSpacing.x10),
          const AlexAvatar(size: 110, emotion: AlexEmotion.celebrate),
          const SizedBox(height: KFSpacing.x5),
          Text(
            l.chatWelcomeTitle(AppConstants.aiCharacterName),
            style: KFTypography.h1(color: palette.ink),
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            l.chatWelcomeSubtitle(settings.targetLanguage.displayName),
            textAlign: TextAlign.center,
            style: KFTypography.body(color: palette.ink2).copyWith(height: 1.5),
          ),
          if (!hasApiKey) ...[
            const SizedBox(height: KFSpacing.x6),
            Container(
              padding: const EdgeInsets.all(KFSpacing.x4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: KFRadii.rXl,
              ),
              child: Column(
                children: [
                  Icon(Icons.key_off,
                      size: 32, color: palette.coral),
                  const SizedBox(height: KFSpacing.x2),
                  Text(
                    l.chatApiKeyRequiredTitle,
                    style: KFTypography.h2(color: palette.ink),
                  ),
                  const SizedBox(height: KFSpacing.x1),
                  Text(
                    l.chatApiKeyRequiredBody,
                    textAlign: TextAlign.center,
                    style: KFTypography.meta(color: palette.ink2),
                  ),
                  const SizedBox(height: KFSpacing.x3),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(l.chatApiKeyGoToSettings),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCelebrationSnack(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
