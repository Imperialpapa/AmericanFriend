import 'dart:math' as math;

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
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';

/// 제시문 pill의 아이콘/버튼은 텍스트만큼 크게 키우면 과해지므로 배율을 제한.
/// 축소(scale < 1) 시에도 24dp 탭 타깃은 유지.
double _chromeScale(double fontScale) => fontScale.clamp(1.0, 1.6);

/// 가로 스크롤 리스트는 높이가 고정이어야 해서, 폰트 스케일에 맞춰 직접 계산.
/// scale 1.0에서 기존 값(36)과 동일.
double _pillHeight(double fontScale) {
  final textHeight = _kPillFontSize * fontScale * 1.35; // KFTypography.meta line-height
  final buttonSize = _kSpeakButtonSize * _chromeScale(fontScale);
  return math.max(textHeight, buttonSize) + 12; // 상하 padding 8 + 여유 4
}

const double _kPillFontSize = 12;
const double _kHintFontSize = 11;
const double _kSpeakButtonSize = 24;

/// Horizontal pill scroll — "Try saying..."
class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final suggestionState = ref.watch(suggestionProvider);
    final showNative = ref.watch(settingsProvider.select((s) => s.showNativeHint));
    // 채팅 본문과 동일한 핀치 스케일을 제시문에도 적용
    final fontScale = ref.watch(settingsProvider.select((s) => s.chatFontScale));

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
                fontSize: 11 * fontScale,
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
              height: _pillHeight(fontScale),
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
                    fontScale: fontScale,
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
  final double fontScale;

  const _SuggestionPill({
    required this.suggestion,
    required this.showNative,
    required this.isFirst,
    required this.fontScale,
  });

  @override
  ConsumerState<_SuggestionPill> createState() => _SuggestionPillState();
}

class _SuggestionPillState extends ConsumerState<_SuggestionPill> {
  bool _isSpeaking = false;

  Future<void> _speak() async {
    final ttsQueue = ref.read(ttsQueueProvider);
    final voice = ref.read(voiceProvider.notifier);
    if (_isSpeaking) {
      await ttsQueue.interrupt();
      if (mounted) setState(() => _isSpeaking = false);
      await voice.resumeHandsFree();
      return;
    }
    // 핸즈프리로 마이크가 열려 있으면 스피커에서 나온 이 소리를 그대로 받아쓴다.
    // 재생 동안 멈춰둔다 (핸즈프리가 꺼져 있으면 no-op).
    await voice.suspendHandsFree();
    if (!mounted) return;
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
    await voice.resumeHandsFree();
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final hasNative = widget.showNative &&
        (widget.suggestion.koreanHint?.isNotEmpty ?? false);
    final scale = widget.fontScale;
    final chrome = _chromeScale(scale);
    final buttonSize = _kSpeakButtonSize * chrome;

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
                Icon(Icons.auto_awesome, size: 11 * chrome, color: palette.mustard),
                const SizedBox(width: 5),
              ],
              Text(
                widget.suggestion.text,
                style: KFTypography.meta(color: palette.ink2).copyWith(
                  fontSize: _kPillFontSize * scale,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              if (hasNative) ...[
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 11 * scale,
                  color: palette.hairline,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.suggestion.koreanHint!,
                  style: KFTypography.meta(color: palette.ink3).copyWith(
                    fontSize: _kHintFontSize * scale,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: _speak,
                customBorder: const CircleBorder(),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isSpeaking ? palette.sageWash : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 14 * chrome,
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
