import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/features/chat/presentation/providers/chat_provider.dart';
import 'package:eng_friend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:eng_friend/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:eng_friend/features/chat/presentation/widgets/suggestion_chips.dart';
import 'package:eng_friend/features/chat/domain/entities/message.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';
import 'package:eng_friend/features/settings/presentation/screens/settings_screen.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/features/streak/presentation/widgets/streak_badge.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/features/topic/presentation/widgets/topic_bottom_sheet.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/features/mission/presentation/widgets/mission_bottom_sheet.dart';
import 'package:eng_friend/features/chat/presentation/widgets/avatar_widget.dart';
import 'package:eng_friend/core/widgets/banner_ad_widget.dart';

/// 메인 채팅 화면
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
    // STT 초기화 (마이크 권한 요청 포함)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final levelState = ref.watch(levelProvider);
    final topicState = ref.watch(topicProvider);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Daily goal reached! Streak: ${next.currentStreak} day${next.currentStreak > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // 미션 완료 축하
    ref.listen(missionProvider, (prev, next) {
      if (next.justCompleted) {
        ref.read(missionProvider.notifier).clearJustCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mission Complete! +${next.starsJustEarned} star${next.starsJustEarned > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
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
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topicState.isActive)
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            topicState.activeTopic!.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => ref.read(topicProvider.notifier).endTopic(),
                          child: const Icon(Icons.close, size: 16, color: Colors.orange),
                        ),
                      ],
                    )
                  else
                    const Text(AppConstants.aiCharacterName,
                        style: TextStyle(fontSize: 16)),
                  Text(
                    'Lv.${levelState.currentLevel} · ${levelState.levelName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const StreakBadge(),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.topic,
              color: topicState.isActive ? Colors.orange : null,
            ),
            tooltip: 'Topics',
            onPressed: () => TopicBottomSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Missions',
            onPressed: () => MissionBottomSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 아바타
          if (ref.watch(settingsProvider.select((s) => s.avatarEnabled)))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AvatarWidget(
                isAnimating: chatState.isAiTyping ||
                    chatState.currentAiResponse.isNotEmpty,
              ),
            ),

          // 에러 표시
          if (chatState.error != null)
            MaterialBanner(
              content: SelectableText(chatState.error!),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: chatState.error!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied!')),
                    );
                  },
                  child: const Text('COPY'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: const Text('SETTINGS'),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(chatProvider.notifier)
                      .updateLevel(chatState.userLevel),
                  child: const Text('DISMISS'),
                ),
              ],
            ),

          // 대화 목록
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isAiTyping
                ? _buildWelcomeMessage()
                : _buildMessageList(chatState),
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

  Widget _buildMessageList(ChatState chatState) {
    // 실제 메시지 + 스트리밍 중인 AI 응답 + 제안 칩(1)
    final hasStreaming =
        chatState.isAiTyping || chatState.currentAiResponse.isNotEmpty;
    final baseCount = chatState.messages.length + (hasStreaming ? 1 : 0);
    // 제안 칩은 항상 마지막에 1칸 추가
    final itemCount = baseCount + 1;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 마지막 아이템 = 제안 칩
        if (index == baseCount) {
          return const SuggestionChips();
        }

        // 스트리밍 중인 AI 응답
        if (index == chatState.messages.length && hasStreaming) {
          return MessageBubble(
            content: chatState.currentAiResponse.isEmpty
                ? '...'
                : chatState.currentAiResponse,
            isUser: false,
            isTyping: chatState.currentAiResponse.isEmpty,
          );
        }

        final message = chatState.messages[index];
        return MessageBubble(
          content: message.content,
          isUser: message.role == MessageRole.user,
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    final settings = ref.watch(settingsProvider);
    final hasApiKey = settings.activeApiKey.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Text('A',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              'Hey! I\'m ${AppConstants.aiCharacterName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'I\'m here to help you practice ${settings.targetLanguage.displayName}.\nLet\'s start a conversation!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            if (!hasApiKey) ...[
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.key_off,
                          size: 32,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 8),
                      Text(
                        'API Key Required',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To start chatting, you need an AI API key.\nSet one up in Settings.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
