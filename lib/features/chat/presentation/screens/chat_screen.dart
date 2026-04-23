import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';
import 'package:eng_friend/core/widgets/banner_ad_widget.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/chat/presentation/widgets/chat_header.dart';
import 'package:eng_friend/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:eng_friend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:eng_friend/features/chat/presentation/widgets/mission_strip.dart';
import 'package:eng_friend/features/chat/presentation/widgets/suggestion_chips.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/settings/presentation/screens/settings_screen.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';

/// 메인 채팅 화면 — Modern Sage redesign.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).initialize();
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

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final chatState = ref.watch(chatProvider);

    // 레벨 변경 시 채팅에 반영
    ref.listen(levelProvider, (prev, next) {
      if (prev?.currentLevel != next.currentLevel) {
        ref.read(chatProvider.notifier).updateLevel(next.currentLevel);
      }
    });

    // streak 목표 달성 축하
    ref.listen(streakProvider, (prev, next) {
      if (next.justReachedGoal) {
        ref.read(streakProvider.notifier).clearJustReachedGoal();
        _showCelebrationSnack(
          context,
          icon: Icons.local_fire_department,
          color: palette.mustard,
          text: 'Daily goal reached! Streak: ${next.currentStreak} day'
              '${next.currentStreak > 1 ? 's' : ''}',
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
          text: 'Mission Complete! +${next.starsJustEarned} star'
              '${next.starsJustEarned > 1 ? 's' : ''}',
        );
      }
    });

    // 메시지 변경 시 자동 스크롤
    ref.listen(chatProvider, (prev, next) {
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

          // 에러 표시
          if (chatState.error != null) _buildErrorBanner(context, chatState.error!),

          // 메시지 영역 + Mission Strip
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isAiTyping
                ? _buildWelcomeMessage()
                : Column(
                    children: [
                      const MissionStrip(),
                      Expanded(child: _buildMessageList(chatState)),
                    ],
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

  Widget _buildErrorBanner(BuildContext context, String error) {
    final palette = KFPalette.of(context);
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
            child: SelectableText(
              error,
              style: KFTypography.meta(color: palette.ink),
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: error));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('Settings'),
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
    final hasApiKey = settings.activeApiKey.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KFSpacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: KFSpacing.x10),
          const AlexAvatar(size: 110, emotion: AlexEmotion.celebrate),
          const SizedBox(height: KFSpacing.x5),
          Text(
            "Hey! I'm ${AppConstants.aiCharacterName}",
            style: KFTypography.h1(color: palette.ink),
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            "I'm here to help you practice ${settings.targetLanguage.displayName}.\nLet's start a conversation!",
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
                    'API Key Required',
                    style: KFTypography.h2(color: palette.ink),
                  ),
                  const SizedBox(height: KFSpacing.x1),
                  Text(
                    'To start chatting, you need an AI API key.\nSet one up in Settings.',
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
                    label: const Text('Go to Settings'),
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
