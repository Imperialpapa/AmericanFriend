import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_shadows.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/chat/presentation/providers/reported_messages_provider.dart';
import 'package:eng_friend/features/chat/presentation/widgets/pronunciation_bottom_sheet.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/features/voice/presentation/providers/voice_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/pipeline/tts_queue.dart';
import 'package:eng_friend/services/report/report_service.dart';

/// Modern Sage message bubble with optional Learning Drawer (AI side).
class MessageBubble extends ConsumerStatefulWidget {
  final String content;
  final bool isUser;
  final bool isTyping;

  /// AI 메시지의 Learning Drawer 초기 펼침 상태 (보통 가장 최근 메시지만 true)
  final bool initialDrawerOpen;

  /// AI 메시지 옆 아바타 표시 여부 (연속된 AI 메시지에서 첫 번째만 표시)
  final bool showAvatar;

  /// 저장된 메시지의 id. 없으면(스트리밍 중인 말풍선) 신고할 수 없다.
  final String? messageId;

  /// 신고할 때 맥락으로 함께 보내는 바로 앞 사용자 메시지.
  final String? prevUserText;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isTyping = false,
    this.initialDrawerOpen = false,
    this.showAvatar = true,
    this.messageId,
    this.prevUserText,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isSpeaking = false;
  bool _revealed = false;
  late bool _drawerOpen;

  @override
  void initState() {
    super.initState();
    _drawerOpen = widget.initialDrawerOpen;
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // State가 재사용된 채로 '가장 최근 AI 답변'이 된 경우에도 교정을 탭 없이 보여 준다.
    // (반대 방향 true→false는 사용자가 열어 둔 드로어를 닫지 않도록 무시)
    if (!oldWidget.initialDrawerOpen && widget.initialDrawerOpen) {
      _drawerOpen = true;
    }
  }

  // --- Helpers ---
  static final _correctionPattern = RegExp(r'^💡\s*.+$', multiLine: true);
  static final _naturalnessTipPattern = RegExp(r'^💬\s*.+$', multiLine: true);
  static final _hintPattern = RegExp(r'(\s*\([^)]+\))');

  ({String body, List<String> corrections, List<String> tips}) _splitCorrections(
      String text) {
    final corrections = <String>[];
    final tips = <String>[];
    var body = text.replaceAllMapped(_correctionPattern, (m) {
      corrections.add(m.group(0)!.replaceFirst(RegExp(r'^💡\s*'), ''));
      return '';
    });
    body = body.replaceAllMapped(_naturalnessTipPattern, (m) {
      tips.add(m.group(0)!.replaceFirst(RegExp(r'^💬\s*'), ''));
      return '';
    });
    return (body: body.trimRight(), corrections: corrections, tips: tips);
  }

  /// 괄호 번역을 제거한 순수 본문 (TTS skip / 단어장 저장 시 사용)
  String _stripParens(String text) => text
      .replaceAll(_hintPattern, '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  /// 본문을 TextSpan으로 렌더 — showNative=true면 (괄호) 부분을 회색으로 인라인 표시
  TextSpan _buildBodySpan(KFPalette palette, String body,
      {required bool showNative, required double fontScale}) {
    final base = KFTypography.body(color: palette.ink).copyWith(
      fontSize: 15 * fontScale,
      letterSpacing: -0.2,
      height: 1.45,
    );
    if (!showNative) {
      return TextSpan(text: _stripParens(body), style: base);
    }
    final hintStyle = base.copyWith(
      color: palette.ink3,
      fontSize: 13 * fontScale,
      fontWeight: FontWeight.w400,
    );
    final spans = <TextSpan>[];
    int last = 0;
    for (final m in _hintPattern.allMatches(body)) {
      if (m.start > last) {
        spans.add(TextSpan(text: body.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(text: m.group(0), style: hintStyle));
      last = m.end;
    }
    if (last < body.length) {
      spans.add(TextSpan(text: body.substring(last), style: base));
    }
    return TextSpan(children: spans);
  }

  Future<void> _speak(String text) async {
    final ttsQueue = ref.read(ttsQueueProvider);
    final voice = ref.read(voiceProvider.notifier);
    if (_isSpeaking) {
      await ttsQueue.interrupt();
      setState(() => _isSpeaking = false);
      await voice.resumeHandsFree();
      return;
    }
    // 핸즈프리로 마이크가 열려 있으면 스피커에서 나온 이 소리를 그대로 받아쓴다.
    // 재생 동안 멈춰둔다 (핸즈프리가 꺼져 있으면 no-op).
    await voice.suspendHandsFree();
    final settings = ref.read(settingsProvider);
    final ttsText = settings.nativeTtsEnabled
        ? text.trim()
        : text
            .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ');

    final cleanTts = ttsText
        .trim()
        .replaceAll(
            RegExp(
              r'[\u{1F000}-\u{1FFFF}]|'
              r'[\u{2600}-\u{27BF}]|'
              r'[\u{FE00}-\u{FE0F}]|'
              r'[\u{200D}]|'
              r'[→←↑↓↔↕]|'
              r'[*_~`]',
              unicode: true,
            ),
            '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (cleanTts.isEmpty) return;

    setState(() => _isSpeaking = true);
    final sub = ttsQueue.stateStream.listen((state) {
      if (state == TtsQueueState.idle && mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    await ttsQueue.enqueue(cleanTts);
    await for (final state in ttsQueue.stateStream) {
      if (state == TtsQueueState.idle) break;
    }
    sub.cancel();
    await voice.resumeHandsFree();
  }

  void _showSaveToVocab(String defaultText) {
    final controller = TextEditingController(text: defaultText);
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.chatSaveToVocabTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l.chatSaveToVocabHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(vocabularyProvider.notifier).addWord(
                      expression: controller.text.trim(),
                    );
                Navigator.pop(dctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.chatSaveToVocabDone),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
  }

  void _showPronunciation(String text) {
    final clean = text
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (clean.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PronunciationBottomSheet(originalText: clean),
    );
  }

  bool get _canReport => widget.messageId != null && !widget.isTyping;

  /// 롱프레스 메뉴. 신고할 수 없는 말풍선(스트리밍 중)은 예전처럼 바로 저장 창을 연다.
  void _showAiMessageMenu(String cleanBody, {required bool reported}) {
    if (!_canReport) {
      _showSaveToVocab(cleanBody);
      return;
    }
    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bookmark_add_outlined, color: palette.sage),
              title: Text(l.chatUserMenuSave),
              onTap: () {
                Navigator.pop(ctx);
                _showSaveToVocab(cleanBody);
              },
            ),
            ListTile(
              enabled: !reported,
              leading: Icon(
                reported ? Icons.flag : Icons.flag_outlined,
                color: palette.coral,
              ),
              title: Text(reported ? l.chatReportedLabel : l.chatReportAction),
              onTap: () {
                Navigator.pop(ctx);
                _startReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startReport() async {
    final id = widget.messageId;
    if (id == null) return;
    final l = AppLocalizations.of(context);
    final palette = KFPalette.of(context);
    // 시트가 열려 있는 동안에도 자동 스크롤로 말풍선이 dispose될 수 있다(스트리밍·핸즈프리).
    // dispose 뒤엔 ref/context를 못 쓰니 시트를 열기 전에 전부 잡아 둔다 — 신고가 조용히 사라지지 않게.
    final settings = ref.read(settingsProvider);
    final service = ref.read(reportServiceProvider);
    final ids = ref.read(reportedMessageIdsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final content = widget.content;
    final prevUserText = widget.prevUserText;
    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  KFSpacing.x5, KFSpacing.x5, KFSpacing.x5, KFSpacing.x1),
              child: Text(l.chatReportSheetTitle,
                  style: KFTypography.h2(color: palette.ink)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  KFSpacing.x5, 0, KFSpacing.x5, KFSpacing.x2),
              child: Text(l.chatReportSheetBody,
                  style: KFTypography.meta(color: palette.ink2)),
            ),
            for (final (r, label) in [
              (ReportReason.harmful, l.chatReportReasonHarmful),
              (ReportReason.incorrect, l.chatReportReasonIncorrect),
              (ReportReason.other, l.chatReportReasonOther),
            ])
              ListTile(
                title: Text(label),
                trailing: Icon(Icons.chevron_right, color: palette.ink3),
                onTap: () => Navigator.pop(ctx, r),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: KFSpacing.x3),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.commonCancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // mounted는 보지 않는다 — 이후는 미리 잡아 둔 값만 쓰므로 말풍선이 사라져도 전송·안내가 된다.
    if (reason == null) return;

    final result = await service.submit(
      AiReport(
        reason: reason,
        message: content,
        prevUser: prevUserText,
        provider: settings.aiProvider.name,
        model: settings.activeModelId,
        locale: locale,
      ),
      deviceId: settings.freeTierDeviceId,
    );
    // 큐에 들어간 신고도 사용자 입장에선 접수된 것 — 같은 답을 두 번 신고하지 않게 표시한다.
    if (result != ReportResult.rejected) {
      ids.state = {...ids.state, id};
    }
    messenger.showSnackBar(SnackBar(
      content: Text(switch (result) {
        ReportResult.sent => l.chatReportSent,
        ReportResult.queued => l.chatReportQueued,
        ReportResult.rejected => l.chatReportFailed,
      }),
      duration: const Duration(seconds: 4),
    ));
  }

  // --- Rendering ---
  @override
  Widget build(BuildContext context) {
    if (widget.isUser) return _buildUserMessage(context);
    return _buildAiMessage(context);
  }

  Widget _buildUserMessage(BuildContext context) {
    final palette = KFPalette.of(context);
    final fontScale = ref.watch(settingsProvider.select((s) => s.chatFontScale));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x4, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showUserMessageMenu(widget.content),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: palette.sage,
                  borderRadius: KFRadii.userBubble,
                  boxShadow: KFShadows.userBubble,
                ),
                child: Text(
                  widget.content,
                  style: KFTypography.body(color: Colors.white).copyWith(
                    fontSize: 15 * fontScale,
                    letterSpacing: -0.2,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMessageMenu(String text) {
    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.mic_none, color: palette.sage),
              title: Text(l.chatUserMenuPractice),
              onTap: () {
                Navigator.pop(ctx);
                _showPronunciation(_stripParens(text));
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark_add_outlined, color: palette.sage),
              title: Text(l.chatUserMenuSave),
              onTap: () {
                Navigator.pop(ctx);
                _showSaveToVocab(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(BuildContext context) {
    final palette = KFPalette.of(context);
    final settings = ref.watch(settingsProvider);
    final fontScale = settings.chatFontScale;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isHidden = !settings.showTargetText && !_revealed;
    final (:body, :corrections, :tips) = _splitCorrections(widget.content);
    final cleanBody = _stripParens(body);

    // 본문이 있으면(타이핑 중 아닌 한) 항상 드로어 열기 가능 — 액션 버튼 접근 보장.
    final hasDrawer = !widget.isTyping && body.trim().isNotEmpty;
    final id = widget.messageId;
    final reported = id != null &&
        ref.watch(reportedMessageIdsProvider.select((s) => s.contains(id)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x4, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            child: widget.showAvatar
                ? const AlexAvatar(size: 28, emotion: AlexEmotion.calm)
                : null,
          ),
          const SizedBox(width: KFSpacing.x2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bubble
                GestureDetector(
                  onTap: () {
                    if (isHidden) {
                      setState(() => _revealed = true);
                      return;
                    }
                    if (hasDrawer) {
                      setState(() => _drawerOpen = !_drawerOpen);
                    }
                  },
                  onLongPress: widget.isTyping
                      ? null
                      : () => _showAiMessageMenu(cleanBody, reported: reported),
                  // 신고한 답은 흐리게 — 무엇을 신고했는지 대화 안에서 알아볼 수 있게.
                  child: AnimatedOpacity(
                    opacity: reported ? 0.45 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: KFRadii.aiBubble,
                        border: isDark
                            ? Border.all(color: palette.hairline, width: 0.5)
                            : null,
                        boxShadow: isDark ? null : KFShadows.card,
                      ),
                      child: widget.isTyping
                          ? const _TypingDots()
                          : isHidden
                              ? Text(
                                  AppLocalizations.of(context)
                                      .chatMessageTapToReveal,
                                  style: KFTypography.body(color: palette.ink3)
                                      .copyWith(
                                    fontSize: 15 * fontScale,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text.rich(
                                  _buildBodySpan(palette, body,
                                      showNative: settings.showNativeHint,
                                      fontScale: fontScale),
                                ),
                    ),
                  ),
                ),

                if (reported)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 12, color: palette.ink3),
                        const SizedBox(width: 3),
                        Text(
                          AppLocalizations.of(context).chatReportedLabel,
                          style: KFTypography.meta(color: palette.ink3)
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                // Learning Drawer (corrections + actions). 인라인 번역은 본문에서 처리됨.
                if (_drawerOpen && hasDrawer && !isHidden) ...[
                  const SizedBox(height: 4),
                  _buildDrawer(palette, corrections, tips, body, cleanBody,
                      reported: reported),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    KFPalette palette,
    List<String> corrections,
    List<String> tips,
    String bodyForTts,
    String cleanBody, {
    required bool reported,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.beige,
        borderRadius: KFRadii.rMd,
        border: Border.all(color: palette.hairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Corrections (grammar / spelling)
          if (corrections.isNotEmpty) ...[
            ...corrections.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _drawerRow(
                    icon: Icons.auto_awesome,
                    iconColor: palette.mustard,
                    child: _correctionText(palette, c),
                  ),
                )),
            const SizedBox(height: 6),
          ],

          // Naturalness tips (backchannel / register / filler)
          if (tips.isNotEmpty) ...[
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _drawerRow(
                    icon: Icons.chat_bubble_outline,
                    iconColor: palette.sageDeep,
                    child: _correctionText(palette, t),
                  ),
                )),
            const SizedBox(height: 6),
          ],

          // Action buttons (always present so 듣기/연습/저장 항상 가능)
          Row(
            children: [
              Expanded(
                child: _drawerButton(
                  icon: Icons.play_arrow_rounded,
                  label: AppLocalizations.of(context).chatDrawerHear,
                  palette: palette,
                  onTap: () => _speak(bodyForTts),
                  active: _isSpeaking,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _drawerButton(
                  icon: Icons.mic_none,
                  label: AppLocalizations.of(context).chatDrawerTry,
                  palette: palette,
                  onTap: () => _showPronunciation(cleanBody),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _drawerButton(
                  icon: Icons.bookmark_add_outlined,
                  label: AppLocalizations.of(context).chatDrawerSave,
                  palette: palette,
                  onTap: () => _showSaveToVocab(cleanBody),
                ),
              ),
              if (_canReport) ...[
                const SizedBox(width: 6),
                _reportButton(palette, reported: reported),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 세 버튼의 폭을 줄이지 않도록 아이콘만 둔다. 라벨은 툴팁·스크린리더로 전달한다.
  Widget _reportButton(KFPalette palette, {required bool reported}) {
    final l = AppLocalizations.of(context);
    final label = reported ? l.chatReportedLabel : l.chatReportAction;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: !reported,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: reported ? null : _startReport,
            borderRadius: BorderRadius.circular(KFRadii.sm),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.paper,
                borderRadius: BorderRadius.circular(KFRadii.sm),
                border: Border.all(color: palette.hairline, width: 1),
              ),
              child: Icon(
                reported ? Icons.flag : Icons.flag_outlined,
                size: 14,
                color: reported ? palette.ink3 : palette.coral,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerRow({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _correctionText(KFPalette palette, String correction) {
    final l = AppLocalizations.of(context);
    final arrowMatch =
        RegExp(r'"([^"]+)"\s*→\s*"([^"]+)"(.*)').firstMatch(correction);
    if (arrowMatch != null) {
      return Text.rich(
        TextSpan(children: [
          TextSpan(
            text: l.chatCorrectionPrefix,
            style: KFTypography.meta(color: palette.ink3).copyWith(fontSize: 12),
          ),
          TextSpan(
            text: arrowMatch.group(1),
            style: KFTypography.meta(color: palette.ink2).copyWith(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              decorationColor: palette.coral,
            ),
          ),
          TextSpan(
            text: l.chatCorrectionArrow,
            style: KFTypography.meta(color: palette.ink3).copyWith(fontSize: 12),
          ),
          TextSpan(
            text: arrowMatch.group(2),
            style: KFTypography.meta(color: palette.sageDeep).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (arrowMatch.group(3)!.trim().isNotEmpty)
            TextSpan(
              text: ' ${arrowMatch.group(3)!.trim()}',
              style:
                  KFTypography.meta(color: palette.ink3).copyWith(fontSize: 11),
            ),
        ]),
      );
    }
    return Text(
      correction,
      style: KFTypography.meta(color: palette.ink2).copyWith(fontSize: 12),
    );
  }

  Widget _drawerButton({
    required IconData icon,
    required String label,
    required KFPalette palette,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KFRadii.sm),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: active ? palette.sageWash : palette.paper,
            borderRadius: BorderRadius.circular(KFRadii.sm),
            border: Border.all(color: palette.hairline, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: active ? palette.sageDeep : palette.sage),
              const SizedBox(width: 5),
              Text(
                label,
                style: KFTypography.meta(color: palette.ink).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    final palette = KFPalette.of(context);
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
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
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.ink3.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
