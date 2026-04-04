import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/voice/domain/entities/voice_state.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';

class VoiceInputButton extends ConsumerWidget {
  const VoiceInputButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final isListening = voiceState.status == VoiceStatus.listening;

    return GestureDetector(
      onTap: () => ref.read(voiceProvider.notifier).toggleListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isListening ? 64 : 48,
        height: isListening ? 64 : 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: isListening ? 28 : 24,
        ),
      ),
    );
  }
}
