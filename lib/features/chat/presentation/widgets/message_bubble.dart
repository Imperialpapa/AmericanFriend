import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final String content;
  final bool isUser;
  final bool isTyping;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isSpeaking = false;
  bool _revealed = false;

  void _showSaveToVocab(BuildContext context) {
    final controller = TextEditingController(text: widget.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Vocabulary'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit expression to save',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(vocabularyProvider.notifier).addWord(
                      expression: controller.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved to vocabulary!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _speak() async {
    final ttsQueue = ref.read(ttsQueueProvider);

    if (_isSpeaking) {
      await ttsQueue.interrupt();
      setState(() => _isSpeaking = false);
      return;
    }

    final settings = ref.read(settingsProvider);
    final ttsText = settings.nativeTtsEnabled
        ? widget.content.trim()
        : widget.content
            .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ');

    setState(() => _isSpeaking = true);

    // TtsQueue의 상태를 구독하여 완료 감지
    final sub = ttsQueue.stateStream.listen((state) {
      if (state == TtsQueueState.idle && mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    await ttsQueue.enqueue(ttsText.trim());

    // idle 상태가 되면 구독 해제
    await for (final state in ttsQueue.stateStream) {
      if (state == TtsQueueState.idle) break;
    }
    sub.cancel();
  }

  /// AI 응답을 대상 언어(기본색) + 모국어 힌트(회색) 로 분리 표시
  /// showNativeHint=false 이면 괄호 부분을 숨김
  TextSpan _buildColoredContent(BuildContext context, String text, {required bool showNative}) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final hintPattern = RegExp(r'(\s*\([^)]+\))');
    final parts = <TextSpan>[];
    int lastEnd = 0;

    for (final match in hintPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }
      if (showNative) {
        parts.add(TextSpan(
          text: match.group(0),
          style: style?.copyWith(color: Colors.grey[400], fontSize: 13),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return TextSpan(children: parts);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final showTarget = settings.showTargetText;
    final showNative = settings.showNativeHint;

    // showTargetText가 off이면 탭해서 공개
    final isHidden = !widget.isUser && !showTarget && !_revealed;

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: isHidden ? () => setState(() => _revealed = true) : null,
        onLongPress: widget.isTyping ? null : () => _showSaveToVocab(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: widget.isUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(widget.isUser ? 16 : 4),
              bottomRight: Radius.circular(widget.isUser ? 4 : 16),
            ),
          ),
          child: widget.isTyping
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _TypingDots(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: widget.isUser
                          ? Text(
                              widget.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : isHidden
                              ? Text(
                                  'Tap to reveal',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                )
                              : Text.rich(
                                  _buildColoredContent(context, widget.content, showNative: showNative),
                                ),
                    ),
                    if (!widget.isUser)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          tooltip: _isSpeaking ? 'Stop' : 'Listen',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.only(right: 8, bottom: 4),
                          constraints: const BoxConstraints(),
                          onPressed: _speak,
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5)
                ? (value * 2).clamp(0.3, 1.0)
                : ((1.0 - value) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(radius: 4),
              ),
            );
          }),
        );
      },
    );
  }
}
