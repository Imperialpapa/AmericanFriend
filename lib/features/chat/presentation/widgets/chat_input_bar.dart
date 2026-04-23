import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_shadows.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/topic/presentation/widgets/topic_bottom_sheet.dart';
import 'package:eng_friend/features/voice/domain/entities/voice_state.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';

/// Composer — Modern Sage style.
/// Layout: [+] (opens topics/missions menu) [text field] [mic / send]
class ChatInputBar extends ConsumerStatefulWidget {
  final void Function(String text) onSendText;

  const ChatInputBar({super.key, required this.onSendText});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final voiceState = ref.watch(voiceProvider);
    final targetLang = ref.watch(settingsProvider.select((s) => s.targetLanguage));
    final isListening = voiceState.status == VoiceStatus.listening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // STT partial result
        if (isListening && voiceState.partialText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: palette.sageWash,
            child: Text(
              voiceState.partialText,
              style: KFTypography.body(color: palette.sageDeep).copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: palette.paper,
            border: Border(
              top: BorderSide(color: palette.hairline, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Plus button — opens topics
              Material(
                color: palette.beige,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => TopicBottomSheet.show(context),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, size: 18, color: palette.ink2),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Text field — beige rounded
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.beige,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !isListening,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: isListening
                          ? 'Listening…'
                          : 'Type or tap mic in ${targetLang.displayName}…',
                      hintStyle: KFTypography.body(color: palette.ink3).copyWith(
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled: false,
                      isDense: true,
                    ),
                    style: KFTypography.body(color: palette.ink).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mic / Send button — sage circle with shadow
              GestureDetector(
                onTap: () {
                  if (_hasText && !isListening) {
                    _send();
                  } else {
                    ref.read(voiceProvider.notifier).toggleListening();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isListening ? palette.coral : palette.sage,
                    shape: BoxShape.circle,
                    boxShadow: KFShadows.sageMic,
                  ),
                  child: Icon(
                    _hasText && !isListening
                        ? Icons.send
                        : (isListening ? Icons.stop : Icons.mic),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
