import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';

class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionState = ref.watch(suggestionProvider);
    final showKorean = ref.watch(settingsProvider.select((s) => s.showKoreanHint));

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
            '이렇게 말해 볼까요?',
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: suggestionState.suggestions.map((suggestion) {
                return ActionChip(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '[${suggestion.text}]',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F), // 노란색
                          ),
                        ),
                        if (showKorean &&
                            suggestion.koreanHint != null &&
                            suggestion.koreanHint!.isNotEmpty)
                          TextSpan(
                            text: ' (${suggestion.koreanHint})',
                            style: const TextStyle(
                              color: Color(0xFF64B5F6), // 파란색
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(suggestionProvider.notifier)
                        .selectSuggestion(suggestion);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
