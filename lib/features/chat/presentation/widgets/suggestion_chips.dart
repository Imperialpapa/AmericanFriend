import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionState = ref.watch(suggestionProvider);
    final showKorean = ref.watch(settingsProvider.select((s) => s.showNativeHint));

    if (suggestionState.suggestions.isEmpty && !suggestionState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Try saying...',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          if (suggestionState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            ...suggestionState.suggestions.map((suggestion) {
              return _SuggestionChipItem(
                suggestion: suggestion,
                showKorean: showKorean,
              );
            }),
        ],
      ),
    );
  }
}

class _SuggestionChipItem extends ConsumerStatefulWidget {
  final Suggestion suggestion;
  final bool showKorean;

  const _SuggestionChipItem({
    required this.suggestion,
    required this.showKorean,
  });

  @override
  ConsumerState<_SuggestionChipItem> createState() =>
      _SuggestionChipItemState();
}

class _SuggestionChipItemState extends ConsumerState<_SuggestionChipItem> {
  bool _isSpeaking = false;

  Future<void> _speak() async {
    final ttsQueue = ref.read(ttsQueueProvider);

    if (_isSpeaking) {
      await ttsQueue.interrupt();
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);

    final sub = ttsQueue.stateStream.listen((state) {
      if (state == TtsQueueState.idle && mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    await ttsQueue.enqueue(widget.suggestion.text.trim());

    await for (final state in ttsQueue.stateStream) {
      if (state == TtsQueueState.idle) break;
    }
    sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref
              .read(suggestionProvider.notifier)
              .selectSuggestion(widget.suggestion);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.suggestion.text,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                      if (widget.showKorean &&
                          widget.suggestion.koreanHint != null &&
                          widget.suggestion.koreanHint!.isNotEmpty)
                        TextSpan(
                          text: '\n${widget.suggestion.koreanHint}',
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: _isSpeaking ? 'Stop' : 'Listen',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: _speak,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
