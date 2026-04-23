import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/features/chat/domain/entities/suggestion.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';

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
              'Try saying…',
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

class _SuggestionPill extends ConsumerWidget {
  final Suggestion suggestion;
  final bool showNative;
  final bool isFirst;

  const _SuggestionPill({
    required this.suggestion,
    required this.showNative,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final hasNative =
        showNative && (suggestion.koreanHint?.isNotEmpty ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KFRadii.rFull,
        onTap: () => ref
            .read(suggestionProvider.notifier)
            .selectSuggestion(suggestion),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: KFRadii.rFull,
            border: Border.all(color: palette.hairline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirst) ...[
                Icon(Icons.auto_awesome, size: 11, color: palette.mustard),
                const SizedBox(width: 5),
              ],
              Text(
                suggestion.text,
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
                  suggestion.koreanHint!,
                  style: KFTypography.meta(color: palette.ink3).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
