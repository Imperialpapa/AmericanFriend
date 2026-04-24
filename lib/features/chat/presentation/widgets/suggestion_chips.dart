import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

/// Horizontal pill scroll — "Try saying..."
class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final suggestionState = ref.watch(suggestionProvider);
    final showNative = ref.watch(settingsProvider.select((s) => s.showNativeHint));

    if (suggestionState.suggestions.isEmpty && !suggestionState.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x4, KFSpacing.x2, 0, KFSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              AppLocalizations.of(context).chatSuggestionTitle,
              style: KFTypography.tiny(color: palette.ink3).copyWith(
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (suggestionState.isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.sage,
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestionState.suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                padding: const EdgeInsets.only(right: KFSpacing.x4),
                itemBuilder: (_, index) {
                  final suggestion = suggestionState.suggestions[index];
                  return _SuggestionPill(
                    suggestion: suggestion,
                    showNative: showNative,
                    isFirst: index == 0,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionPill extends ConsumerStatefulWidget {
  final Suggestion suggestion;
  final bool showNative;
  final bool isFirst;

  const _SuggestionPill({
    required this.suggestion,
    required this.showNative,
    required this.isFirst,
  });

  @override
  ConsumerState<_SuggestionPill> createState() => _SuggestionPillState();
}

class _SuggestionPillState extends ConsumerState<_SuggestionPill> {
  bool _isSpeaking = false;

  Future<void> _speak() async {
    final ttsQueue = ref.read(ttsQueueProvider);
    if (_isSpeaking) {
      await ttsQueue.interrupt();
      if (mounted) setState(() => _isSpeaking = false);
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
    final palette = KFPalette.of(context);
    final hasNative = widget.showNative &&
        (widget.suggestion.koreanHint?.isNotEmpty ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KFRadii.rFull,
        onTap: () => ref
            .read(suggestionProvider.notifier)
            .selectSuggestion(widget.suggestion),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 4, 4, 4),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: KFRadii.rFull,
            border: Border.all(color: palette.hairline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isFirst) ...[
                Icon(Icons.auto_awesome, size: 11, color: palette.mustard),
                const SizedBox(width: 5),
              ],
              Text(
                widget.suggestion.text,
                style: KFTypography.meta(color: palette.ink2).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              if (hasNative) ...[
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 11,
                  color: palette.hairline,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.suggestion.koreanHint!,
                  style: KFTypography.meta(color: palette.ink3).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: _speak,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isSpeaking ? palette.sageWash : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 14,
                    color: _isSpeaking ? palette.sageDeep : palette.ink3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
