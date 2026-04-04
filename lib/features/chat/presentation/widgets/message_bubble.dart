import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

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

  Future<void> _speak() async {
    final ttsQueue = ref.read(ttsQueueProvider);

    if (_isSpeaking) {
      await ttsQueue.interrupt();
      setState(() => _isSpeaking = false);
      return;
    }

    // 한글 번역 괄호 + 잔여 한글 문자 제거 후 영어만 읽기
    final englishOnly = widget.content
        .replaceAll(RegExp(r'\s*\([^)]*[가-힣]+[^)]*\)'), '')
        .replaceAll(RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣ]+'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ');

    setState(() => _isSpeaking = true);

    // TtsQueue의 상태를 구독하여 완료 감지
    final sub = ttsQueue.stateStream.listen((state) {
      if (state == TtsQueueState.idle && mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    await ttsQueue.enqueue(englishOnly.trim());

    // idle 상태가 되면 구독 해제
    await for (final state in ttsQueue.stateStream) {
      if (state == TtsQueueState.idle) break;
    }
    sub.cancel();
  }

  /// AI 응답에서 영어는 흰색, 한글(괄호)은 밝은 회색으로 표시
  TextSpan _buildColoredContent(BuildContext context, String text) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final koreanPattern = RegExp(r'(\([^)]*[가-힣]+[^)]*\))');
    final parts = <TextSpan>[];
    int lastEnd = 0;

    for (final match in koreanPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }
      parts.add(TextSpan(
        text: match.group(0),
        style: style?.copyWith(color: Colors.grey[400], fontSize: 13),
      ));
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

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                        : Text.rich(
                            _buildColoredContent(context, widget.content),
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
                        tooltip: _isSpeaking ? '중지' : '다시 듣기',
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
