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

    // 레벨 변경 시 채팅에 반영
    ref.listen(levelProvider, (prev, next) {
      if (prev?.currentLevel != next.currentLevel) {
        ref.read(chatProvider.notifier).updateLevel(next.currentLevel);
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppConstants.aiCharacterName,
                    style: TextStyle(fontSize: 16)),
                Text(
                  'Lv.${levelState.currentLevel} · ${levelState.levelName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
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

          // 입력 바
          ChatInputBar(
            onSendText: (text) =>
                ref.read(chatProvider.notifier).sendMessage(text),
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
    final targetLang = ref.watch(settingsProvider.select((s) => s.targetLanguage));

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
              'I\'m here to help you practice ${targetLang.displayName}.\nLet\'s start a conversation!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
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
