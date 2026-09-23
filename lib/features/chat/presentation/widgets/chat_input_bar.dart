import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_shadows.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/topic/presentation/widgets/topic_bottom_sheet.dart';
import 'package:eng_friend/features/voice/domain/entities/voice_state.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    final voiceState = ref.watch(voiceProvider);
    final targetLang = ref.watch(settingsProvider.select((s) => s.targetLanguage));
    final isListening = voiceState.status == VoiceStatus.listening;

    // 자동 전송 OFF 모드에서 STT 결과를 컨트롤러로 옮긴 뒤 voice 상태의 draft를 비움.
    ref.listen<VoiceState>(voiceProvider, (prev, next) {
      if (next.recognizedDraft.isNotEmpty &&
          next.recognizedDraft != prev?.recognizedDraft) {
        _controller.text = next.recognizedDraft;
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
        ref.read(voiceProvider.notifier).clearDraft();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 핸즈프리 상태 배너 — 마이크가 저절로 열리는 모드이므로 상태를 항상 명시
        if (voiceState.handsFreeActive)
          _HandsFreeBanner(voiceState: voiceState, palette: palette, l: l),

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
              const SizedBox(width: 6),

              // Hands-free toggle — 켜면 마이크 버튼 없이 대화가 순환한다
              Material(
                color: voiceState.handsFreeActive
                    ? palette.sageWash
                    : palette.beige,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final notifier = ref.read(voiceProvider.notifier);
                    await notifier.toggleHandsFree();
                    // 다음 실행에도 기억되도록 선호를 저장
                    if (!context.mounted) return;
                    await ref
                        .read(settingsProvider.notifier)
                        .setHandsFreeEnabled(
                            ref.read(voiceProvider).handsFreeActive);
                  },
                  child: Tooltip(
                    message: voiceState.handsFreeActive
                        ? l.handsFreeTurnOff
                        : l.handsFreeTurnOn,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        voiceState.handsFreeActive
                            ? Icons.record_voice_over
                            : Icons.record_voice_over_outlined,
                        size: 18,
                        color: voiceState.handsFreeActive
                            ? palette.sageDeep
                            : palette.ink2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

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
                          ? l.chatInputHintListening
                          : l.chatInputHintTyping(targetLang.displayName),
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

/// 핸즈프리가 켜져 있는 동안 입력바 위에 상시 표시되는 상태 줄.
/// 마이크가 사용자 조작 없이 열리는 모드라, 지금 듣는 중인지 말하는 중인지를
/// 항상 보이게 해서 "모르는 사이에 녹음되는" 상황을 없앤다.
class _HandsFreeBanner extends ConsumerWidget {
  final VoiceState voiceState;
  final KFPalette palette;
  final AppLocalizations l;

  const _HandsFreeBanner({
    required this.voiceState,
    required this.palette,
    required this.l,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, dotColor) = switch (voiceState) {
      VoiceState(handsFreeSuspended: true) => (l.handsFreePaused, palette.ink3),
      VoiceState(status: VoiceStatus.listening) => (
          l.handsFreeListening,
          palette.coral
        ),
      VoiceState(status: VoiceStatus.processing) => (
          l.handsFreeThinking,
          palette.mustard
        ),
      VoiceState(status: VoiceStatus.speaking) => (
          l.handsFreeSpeaking,
          palette.sageDeep
        ),
      _ => (l.handsFreeListening, palette.sage),
    };

    return Semantics(
      // 마이크가 저절로 열리는 모드라 상태 변화가 스크린리더에도 읽혀야 한다
      liveRegion: true,
      label: '${l.handsFreeLabel} $label',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        color: palette.sageWash,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l.handsFreeLabel} · $label',
                style: KFTypography.meta(color: palette.ink2)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(voiceProvider.notifier).stopHandsFree();
                await ref
                    .read(settingsProvider.notifier)
                    .setHandsFreeEnabled(false);
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                l.handsFreeStop,
                style: KFTypography.meta(color: palette.sageDeep)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
