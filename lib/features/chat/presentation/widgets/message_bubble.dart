import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/features/chat/presentation/widgets/pronunciation_bottom_sheet.dart';

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
    // 교정 라인(💡) 제거 후 본문만 TTS
    final (:body, corrections: _) = _splitCorrections(widget.content);
    final ttsText = settings.nativeTtsEnabled
        ? body.trim()
        : body
            .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ');

    // 이모지, 특수문자 제거 (TTS가 읽지 않도록)
    final cleanTts = ttsText
        .trim()
        .replaceAll(RegExp(
          r'[\u{1F000}-\u{1FFFF}]|'
          r'[\u{2600}-\u{27BF}]|'
          r'[\u{FE00}-\u{FE0F}]|'
          r'[\u{200D}]|'
          r'[→←↑↓↔↕]|'
          r'[*_~`]',
          unicode: true,
        ), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    if (cleanTts.isEmpty) return;

    setState(() => _isSpeaking = true);

    // TtsQueue의 상태를 구독하여 완료 감지
    final sub = ttsQueue.stateStream.listen((state) {
      if (state == TtsQueueState.idle && mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    await ttsQueue.enqueue(cleanTts);

    // idle 상태가 되면 구독 해제
    await for (final state in ttsQueue.stateStream) {
      if (state == TtsQueueState.idle) break;
    }
    sub.cancel();
  }

  Widget _buildBubbleContent(
      BuildContext context, ColorScheme colorScheme, bool isHidden, bool showNative) {
    final (:body, :corrections) = widget.isUser
        ? (body: widget.content, corrections: <String>[])
        : _splitCorrections(widget.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: widget.isUser
              ? Text(body, style: Theme.of(context).textTheme.bodyMedium)
              : isHidden
                  ? Text(
                      'Tap to reveal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                    )
                  : Text.rich(
                      _buildColoredContent(context, body, showNative: showNative),
                    ),
        ),
        // 문법 교정 표시
        if (!widget.isUser && corrections.isNotEmpty && !isHidden)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: corrections.map((c) {
                  // "wrong" → "right" 패턴 파싱
                  final arrowMatch = RegExp(r'"([^"]+)"\s*→\s*"([^"]+)"(.*)').firstMatch(c);
                  if (arrowMatch != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: '💡 ', style: TextStyle(fontSize: 13)),
                          TextSpan(
                            text: arrowMatch.group(1),
                            style: const TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.redAccent,
                            ),
                          ),
                          const TextSpan(
                            text: ' → ',
                            style: TextStyle(fontSize: 13),
                          ),
                          TextSpan(
                            text: arrowMatch.group(2),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          if (arrowMatch.group(3)!.trim().isNotEmpty)
                            TextSpan(
                              text: ' ${arrowMatch.group(3)!.trim()}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                        ]),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('💡 $c', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
              ),
            ),
          ),
        Align(
          alignment: widget.isUser ? Alignment.centerLeft : Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.mic, size: 18),
                tooltip: 'Repeat after me',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: colorScheme.onSurfaceVariant,
                onPressed: () => _showPronunciationPractice(context, body),
              ),
              if (!widget.isUser) ...[
                const SizedBox(width: 8),
                IconButton(
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
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  void _showPronunciationPractice(BuildContext context, String text) {
    // 괄호 번역 제거하고 순수 대상 언어 텍스트만 추출
    final cleanText = text
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (cleanText.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PronunciationBottomSheet(originalText: cleanText),
    );
  }

  /// 💡 교정 라인을 분리
  static final _correctionPattern = RegExp(r'^💡\s*.+$', multiLine: true);

  /// AI 응답에서 교정 라인을 제거한 본문과 교정 목록을 분리
  ({String body, List<String> corrections}) _splitCorrections(String text) {
    final corrections = <String>[];
    final body = text.replaceAllMapped(_correctionPattern, (m) {
      corrections.add(m.group(0)!.replaceFirst(RegExp(r'^💡\s*'), ''));
      return '';
    }).trimRight();
    return (body: body, corrections: corrections);
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
              : _buildBubbleContent(context, colorScheme, isHidden, showNative),
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
