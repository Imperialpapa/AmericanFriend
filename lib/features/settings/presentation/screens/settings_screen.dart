import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/constants/level_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_shadows.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';
import 'package:eng_friend/core/widgets/banner_ad_widget.dart';
import 'package:eng_friend/core/widgets/kf_xp_bar.dart';
import 'package:eng_friend/features/chat/presentation/providers/suggestion_provider.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/report/presentation/screens/weekly_report_screen.dart';
import 'package:eng_friend/features/settings/domain/entities/user_settings.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/services/ai/free_tier/free_tier_ai_service.dart';
import 'package:eng_friend/services/language/app_language.dart';
import 'package:eng_friend/services/notification/notification_service.dart';

/// Profile-forward settings screen — Modern Sage redesign.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _claudeKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _groqKeyController = TextEditingController();
  final Map<String, bool> _showKey = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _claudeKeyController.text = settings.claudeApiKey;
      _openaiKeyController.text = settings.openaiApiKey;
      _geminiKeyController.text = settings.geminiApiKey;
      _groqKeyController.text = settings.groqApiKey;
    });
  }

  @override
  void dispose() {
    _claudeKeyController.dispose();
    _openaiKeyController.dispose();
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _Header(palette: palette),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: KFSpacing.x6),
                children: [
                  const _HeroCard(),
                  const SizedBox(height: KFSpacing.x2),
                  _SectionTitle(l.settingsSectionLearning, palette: palette),
                  _LearningGroup(
                    settings: settings,
                    notifier: notifier,
                    palette: palette,
                  ),
                  _LanguageWarningBanner(
                      settings: settings, palette: palette),
                  _SectionTitle(l.settingsSectionAi, palette: palette),
                  _AiGroup(
                    settings: settings,
                    notifier: notifier,
                    palette: palette,
                    keyController: _controllerFor(settings.aiProvider),
                    onKeyChanged: (v) =>
                        _saveKey(notifier, settings.aiProvider, v),
                    onToggleKeyVisible: () {
                      setState(() {
                        final tag = settings.aiProvider.name;
                        _showKey[tag] = !(_showKey[tag] ?? false);
                      });
                    },
                    keyVisible: _showKey[settings.aiProvider.name] ?? false,
                  ),
                  _SectionTitle(l.settingsSectionConversation, palette: palette),
                  _ConversationGroup(
                    settings: settings,
                    notifier: notifier,
                    palette: palette,
                  ),
                  _SectionTitle(l.settingsSectionVoice, palette: palette),
                  _VoiceGroup(
                    settings: settings,
                    notifier: notifier,
                    palette: palette,
                  ),
                  _SectionTitle(l.settingsSectionApp, palette: palette),
                  _AppGroup(
                    settings: settings,
                    notifier: notifier,
                    palette: palette,
                    onFeedback: () => _launchFeedback(settings),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        KFSpacing.x5, KFSpacing.x5, KFSpacing.x5, 0),
                    child: Center(
                      child: Text(
                        '${AppConstants.appName} · v${AppConstants.appVersion}',
                        style: KFTypography.tiny(color: palette.ink3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  TextEditingController _controllerFor(AiProviderType provider) {
    return switch (provider) {
      AiProviderType.freeTier => _claudeKeyController, // 쓰이지 않음 (freeTier는 키 필드 없음)
      AiProviderType.claude => _claudeKeyController,
      AiProviderType.openai => _openaiKeyController,
      AiProviderType.gemini => _geminiKeyController,
      AiProviderType.groq => _groqKeyController,
    };
  }

  void _saveKey(SettingsNotifier notifier, AiProviderType provider, String v) {
    switch (provider) {
      case AiProviderType.freeTier:
        return; // 저장할 키 없음
      case AiProviderType.claude:
        notifier.setClaudeApiKey(v);
      case AiProviderType.openai:
        notifier.setOpenaiApiKey(v);
      case AiProviderType.gemini:
        notifier.setGeminiApiKey(v);
      case AiProviderType.groq:
        notifier.setGroqApiKey(v);
    }
  }

  Future<void> _launchFeedback(UserSettings settings) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'raphael70kim@gmail.com',
      queryParameters: {
        'subject': '[Korean Friend] Feedback',
        'body':
            '\n\n---\nApp: ${AppConstants.appName} v${AppConstants.appVersion}\nAI: ${settings.aiProvider.name} (${settings.activeModelId})\nLevel: ${ref.read(levelProvider).currentLevel}\nNative: ${settings.nativeLanguage.displayName}\nTarget: ${settings.targetLanguage.displayName}',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).settingsFeedbackEmailFailed)),
      );
    }
  }
}

// ===================
// Header
// ===================
class _Header extends StatelessWidget {
  final KFPalette palette;
  const _Header({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x5, KFSpacing.x4, KFSpacing.x3, KFSpacing.x4),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context).settingsHeaderTitle,
            style: KFTypography.h1(color: palette.ink).copyWith(fontSize: 24),
          ),
          const Spacer(),
          Material(
            color: palette.beige,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(Icons.close, size: 16, color: palette.ink2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================
// HeroCard
// ===================
class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelState = ref.watch(levelProvider);
    final streakState = ref.watch(streakProvider);
    final vocabState = ref.watch(vocabularyProvider);

    final levelProgress =
        (levelState.currentLevel / LevelConstants.maxLevel).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KFSpacing.x4),
      padding: const EdgeInsets.all(KFSpacing.x4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: KFRadii.rXxl,
        border: Border.all(color: palette.hairline),
        boxShadow: isDark ? null : KFShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Level avatar (sage circle with level number)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [palette.sageWash, palette.sageSoft],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.hairline),
                      ),
                      child: Center(
                        child: Text(
                          '${levelState.currentLevel}',
                          style: KFTypography.h2(color: palette.sageDeep)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    // Alex pebble overlap
                    Positioned(
                      right: -6,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: palette.card,
                          shape: BoxShape.circle,
                        ),
                        child: const AlexAvatar(
                            size: 26, emotion: AlexEmotion.celebrate),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KFSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .settingsHeroLevelLearner(levelState.currentLevel),
                      style: KFTypography.h2(color: palette.ink).copyWith(
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      LevelConstants.levelNames[levelState.currentLevel],
                      style: KFTypography.meta(color: palette.ink3)
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    KFXpBar(value: levelProgress),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KFSpacing.x3),
          Builder(builder: (context) {
            final l = AppLocalizations.of(context);
            return Row(
              children: [
                _StatPill(
                  label: l.settingsStatStreak,
                  value: '${streakState.currentStreak}',
                  sub: l.settingsStatStreakSub,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: l.settingsStatWords,
                  value: '${vocabState.allItems.length}',
                  sub: l.settingsStatWordsSub,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: l.settingsStatToday,
                  value: '${streakState.todayMessageCount}',
                  sub: l.settingsStatTodaySub(streakState.dailyGoal),
                  palette: palette,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final KFPalette palette;

  const _StatPill({
    required this.label,
    required this.value,
    required this.sub,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: KFSpacing.x2 + 2, vertical: 10),
        decoration: BoxDecoration(
          color: palette.beige,
          borderRadius: KFRadii.rMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: KFTypography.tiny(color: palette.ink3).copyWith(
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: KFTypography.h2(color: palette.ink).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    sub,
                    style: KFTypography.tiny(color: palette.ink3).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===================
// Section helpers
// ===================
class _SectionTitle extends StatelessWidget {
  final String text;
  final KFPalette palette;
  const _SectionTitle(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x5, KFSpacing.x5, KFSpacing.x5, KFSpacing.x2),
      child: Text(
        text.toUpperCase(),
        style: KFTypography.tiny(color: palette.ink3).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  final KFPalette palette;
  const _Group({required this.children, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KFSpacing.x4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: KFRadii.rXl,
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          final isLast = i == children.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              children[i],
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: palette.hairline,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Generic row: icon tile + title + optional detail + chevron when tappable.
class _Row extends StatelessWidget {
  final IconData icon;
  final Color? iconTint;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final KFPalette palette;

  const _Row({
    required this.icon,
    required this.title,
    required this.palette,
    this.iconTint,
    this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: KFSpacing.x3 + 2, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconTint ?? palette.beige,
                  borderRadius: BorderRadius.circular(KFRadii.xs + 3),
                ),
                child: Icon(icon, size: 16, color: palette.ink),
              ),
              const SizedBox(width: KFSpacing.x3),
              Expanded(
                child: Text(
                  title,
                  style: KFTypography.body(color: palette.ink).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (detail != null) ...[
                Text(
                  detail!,
                  style: KFTypography.meta(color: palette.ink3)
                      .copyWith(fontSize: 13),
                ),
                const SizedBox(width: 6),
              ],
              if (onTap != null)
                Icon(Icons.chevron_right, size: 16, color: palette.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline row containing custom child below the title.
class _InlineRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final KFPalette palette;

  const _InlineRow({
    required this.icon,
    required this.title,
    required this.child,
    required this.palette,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x3 + 2, 12, KFSpacing.x3 + 2, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.beige,
                  borderRadius: BorderRadius.circular(KFRadii.xs + 3),
                ),
                child: Icon(icon, size: 16, color: palette.ink),
              ),
              const SizedBox(width: KFSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KFTypography.body(color: palette.ink).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: KFTypography.meta(color: palette.ink3)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KFSpacing.x3),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ===================
// Group: Learning
// ===================
class _LearningGroup extends StatelessWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;

  const _LearningGroup({
    required this.settings,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Group(
      palette: palette,
      children: [
        _Row(
          icon: Icons.style_outlined,
          iconTint: palette.sageWash,
          title: l.settingsRowVocabulary,
          detail: l.settingsRowVocabularyDetail,
          palette: palette,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VocabularyScreen()),
            );
          },
        ),
        _Row(
          icon: Icons.bar_chart_rounded,
          iconTint: palette.mustardSoft,
          title: l.settingsRowWeeklyReport,
          detail: l.settingsRowWeeklyReportDetail,
          palette: palette,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
            );
          },
        ),
        _LevelInlineRow(palette: palette),
        _LanguageInlineRow(
          settings: settings,
          notifier: notifier,
          palette: palette,
          isNative: true,
        ),
        _LanguageInlineRow(
          settings: settings,
          notifier: notifier,
          palette: palette,
          isNative: false,
        ),
      ],
    );
  }
}

class _LevelInlineRow extends ConsumerWidget {
  final KFPalette palette;
  const _LevelInlineRow({required this.palette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);
    final level = levelState.currentLevel;

    final l = AppLocalizations.of(context);
    return _InlineRow(
      icon: Icons.adjust,
      title: l.settingsRowLevel,
      subtitle: '$level · ${LevelConstants.levelNames[level]}',
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: level.toDouble(),
            min: LevelConstants.minLevel.toDouble(),
            max: LevelConstants.maxLevel.toDouble(),
            divisions: LevelConstants.maxLevel - LevelConstants.minLevel,
            label: '$level',
            onChanged: (v) {
              ref.read(levelProvider.notifier).setLevel(v.round());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text(
              _levelDescription(l, level),
              style: KFTypography.meta(color: palette.ink3)
                  .copyWith(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _levelDescription(AppLocalizations l, int level) => switch (level) {
        1 => l.levelDesc1,
        2 => l.levelDesc2,
        3 => l.levelDesc3,
        4 => l.levelDesc4,
        5 => l.levelDesc5,
        6 => l.levelDesc6,
        7 => l.levelDesc7,
        8 => l.levelDesc8,
        9 => l.levelDesc9,
        10 => l.levelDesc10,
        _ => '',
      };
}

class _LanguageInlineRow extends StatelessWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;
  final bool isNative;

  const _LanguageInlineRow({
    required this.settings,
    required this.notifier,
    required this.palette,
    required this.isNative,
  });

  @override
  Widget build(BuildContext context) {
    final value = isNative ? settings.nativeLanguage : settings.targetLanguage;
    final disabled =
        isNative ? settings.targetLanguage : settings.nativeLanguage;

    final l = AppLocalizations.of(context);
    return _Row(
      icon: isNative ? Icons.translate : Icons.school_outlined,
      title: isNative ? l.settingsRowNativeLanguage : l.settingsRowTargetLanguage,
      detail: value.displayName,
      palette: palette,
      onTap: () => _pickLanguage(context, value, disabled),
    );
  }

  Future<void> _pickLanguage(
      BuildContext context, AppLanguage current, AppLanguage disabled) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KFSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: KFSpacing.x3, vertical: KFSpacing.x2),
                  child: Text(
                    isNative
                        ? l.settingsRowNativeLanguage
                        : l.settingsRowTargetLanguage,
                    style: KFTypography.h2(color: palette.ink),
                  ),
                ),
                ...AppLanguage.values.map((lang) {
                  final isCurrent = lang == current;
                  final isDisabled = lang == disabled;
                  return ListTile(
                    enabled: !isDisabled,
                    title: Text(lang.label,
                        style: KFTypography.body(
                            color: isDisabled ? palette.ink3 : palette.ink)),
                    trailing: isCurrent
                        ? Icon(Icons.check, color: palette.sage)
                        : null,
                    onTap: () => Navigator.pop(ctx, lang),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != current) {
      if (isNative) {
        await notifier.setNativeLanguage(picked);
      } else {
        await notifier.setTargetLanguage(picked);
      }
    }
  }
}

// ===================
// Free tier quota row — fetches current usage from proxy
// ===================
class _FreeTierQuotaRow extends ConsumerStatefulWidget {
  final KFPalette palette;
  const _FreeTierQuotaRow({required this.palette});

  @override
  ConsumerState<_FreeTierQuotaRow> createState() => _FreeTierQuotaRowState();
}

class _FreeTierQuotaRowState extends ConsumerState<_FreeTierQuotaRow> {
  FreeTierQuota? _quota;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final service = ref.read(aiServiceProvider);
    if (service is! FreeTierAiService) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final q = await service.fetchQuota();
    if (mounted) {
      setState(() {
        _quota = q;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final q = _quota;

    String title;
    String subtitle;
    double progress;
    if (_loading) {
      title = 'Checking usage…';
      subtitle = '';
      progress = 0;
    } else if (q == null) {
      title = 'Offline';
      subtitle = 'Cannot reach proxy';
      progress = 0;
    } else {
      title = 'Today: ${q.used} / ${q.limit} free';
      subtitle = q.remaining > 0
          ? 'Resets at UTC midnight'
          : 'Limit reached — add API key for unlimited';
      progress = q.limit > 0 ? (q.used / q.limit).clamp(0.0, 1.0) : 0;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x3 + 2, 12, KFSpacing.x3 + 2, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.sageWash,
                  borderRadius: BorderRadius.circular(KFRadii.xs + 3),
                ),
                child: Icon(Icons.bolt, size: 16, color: palette.sageDeep),
              ),
              const SizedBox(width: KFSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KFTypography.body(color: palette.ink).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: KFTypography.meta(color: palette.ink3)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KFSpacing.x3),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: KFXpBar(value: progress),
          ),
        ],
      ),
    );
  }
}

// ===================
// Language compatibility warning banner
// ===================
class _LanguageWarningBanner extends StatelessWidget {
  final UserSettings settings;
  final KFPalette palette;

  const _LanguageWarningBanner({
    required this.settings,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final warnings = <String>[];
    final native = settings.aiProvider.supportFor(settings.nativeLanguage);
    final target = settings.aiProvider.supportFor(settings.targetLanguage);
    if (native.warningMessage != null) warnings.add(native.warningMessage!);
    if (target.warningMessage != null) warnings.add(target.warningMessage!);

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x4, KFSpacing.x3, KFSpacing.x4, 0),
      child: Container(
        padding: const EdgeInsets.all(KFSpacing.x3),
        decoration: BoxDecoration(
          color: palette.mustardSoft,
          borderRadius: KFRadii.rMd,
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18, color: palette.mustard),
            const SizedBox(width: KFSpacing.x2),
            Expanded(
              child: Text(
                warnings.join('\n'),
                style: KFTypography.meta(color: palette.ink2)
                    .copyWith(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================
// Group: AI
// ===================
class _AiGroup extends StatelessWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;
  final TextEditingController keyController;
  final ValueChanged<String> onKeyChanged;
  final VoidCallback onToggleKeyVisible;
  final bool keyVisible;

  const _AiGroup({
    required this.settings,
    required this.notifier,
    required this.palette,
    required this.keyController,
    required this.onKeyChanged,
    required this.onToggleKeyVisible,
    required this.keyVisible,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFreeTier = settings.aiProvider == AiProviderType.freeTier;
    return _Group(
      palette: palette,
      children: [
        _Row(
          icon: Icons.bolt_outlined,
          iconTint: palette.sageWash,
          title: l.settingsRowProvider,
          detail: _providerName(settings.aiProvider),
          palette: palette,
          onTap: () => _pickProvider(context),
        ),
        if (!isFreeTier)
          _Row(
            icon: Icons.smart_toy_outlined,
            title: l.settingsRowModel,
            detail: _modelDisplayName(settings),
            palette: palette,
            onTap: () => _pickModel(context),
          ),
        if (isFreeTier)
          _FreeTierQuotaRow(palette: palette)
        else
          _InlineRow(
          icon: Icons.key_outlined,
          title: l.settingsRowApiKey,
          subtitle: _providerKeyHint(settings.aiProvider),
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Get free key" action — opens provider's key page in browser
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchKeyUrl(settings.aiProvider),
                  borderRadius: KFRadii.rSm,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: palette.sageWash,
                      borderRadius: KFRadii.rSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 14, color: palette.sageDeep),
                        const SizedBox(width: 6),
                        Text(
                          l.settingsGetFreeKey(
                              _providerKeyHint(settings.aiProvider)),
                          style: KFTypography.meta(color: palette.sageDeep)
                              .copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KFSpacing.x2),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: keyController,
                      obscureText: !keyVisible,
                      onChanged: (v) => onKeyChanged(v.trim()),
                      decoration: InputDecoration(
                        hintText: l.settingsApiKeyHint,
                        isDense: true,
                      ),
                      style: KFTypography.body(color: palette.ink).copyWith(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      keyVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: palette.ink2,
                    ),
                    onPressed: onToggleKeyVisible,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _providerKeyUrl(AiProviderType p) => switch (p) {
        AiProviderType.freeTier => '',
        AiProviderType.gemini => 'https://aistudio.google.com/apikey',
        AiProviderType.groq => 'https://console.groq.com/keys',
        AiProviderType.claude => 'https://console.anthropic.com/settings/keys',
        AiProviderType.openai => 'https://platform.openai.com/api-keys',
      };

  Future<void> _launchKeyUrl(AiProviderType p) async {
    final uri = Uri.parse(_providerKeyUrl(p));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _providerName(AiProviderType p) => switch (p) {
        AiProviderType.freeTier => 'Free (no key)',
        AiProviderType.gemini => 'Google Gemini',
        AiProviderType.groq => 'Groq (Llama 3.3)',
        AiProviderType.claude => 'Claude',
        AiProviderType.openai => 'OpenAI',
      };

  String _modelDisplayName(UserSettings s) {
    final model = s.aiProvider.availableModels
        .firstWhere((m) => m.id == s.activeModelId,
            orElse: () => s.aiProvider.availableModels.first);
    return model.displayName;
  }

  String _providerKeyHint(AiProviderType p) => switch (p) {
        AiProviderType.freeTier => '',
        AiProviderType.gemini => 'aistudio.google.com/apikey',
        AiProviderType.groq => 'console.groq.com/keys',
        AiProviderType.claude => 'console.anthropic.com',
        AiProviderType.openai => 'platform.openai.com/api-keys',
      };

  void _pickProvider(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KFSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(KFSpacing.x3),
                  child: Text(l.settingsPickerProvider,
                      style: KFTypography.h2(color: palette.ink)),
                ),
                ...AiProviderType.values.map((p) {
                  final selected = p == settings.aiProvider;
                  return ListTile(
                    title: Text(_providerName(p),
                        style: KFTypography.body(color: palette.ink)),
                    subtitle: Text(_providerDescription(p),
                        style: KFTypography.meta(color: palette.ink3)),
                    trailing: selected
                        ? Icon(Icons.check, color: palette.sage)
                        : null,
                    onTap: () {
                      notifier.setAiProvider(p);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _providerDescription(AiProviderType p) => switch (p) {
        AiProviderType.freeTier => 'No API key required · 20 msg/day',
        AiProviderType.gemini => 'Free tier · 1,500 req/day',
        AiProviderType.groq => 'Free · 14,400 req/day, ultra fast',
        AiProviderType.claude => 'Paid · highest quality',
        AiProviderType.openai => 'Paid · GPT-4o',
      };

  void _pickModel(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KFSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(KFSpacing.x3),
                  child: Text(l.settingsPickerModel,
                      style: KFTypography.h2(color: palette.ink)),
                ),
                ...settings.aiProvider.availableModels.map((m) {
                  final selected = m.id == settings.activeModelId;
                  return ListTile(
                    title: Text(m.displayName,
                        style: KFTypography.body(color: palette.ink)),
                    subtitle: Text(m.description,
                        style: KFTypography.meta(color: palette.ink3)),
                    trailing: selected
                        ? Icon(Icons.check, color: palette.sage)
                        : null,
                    onTap: () {
                      notifier.setModelId(settings.aiProvider, m.id);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================
// Group: Conversation
// ===================
class _ConversationGroup extends StatelessWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;

  const _ConversationGroup({
    required this.settings,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Group(
      palette: palette,
      children: [
        _SwitchRow(
          icon: Icons.subtitles_outlined,
          title: l.settingsShowTargetText(settings.targetLanguage.displayName),
          subtitle: l.settingsShowTargetTextSub,
          value: settings.showTargetText,
          onChanged: notifier.setShowTargetText,
          palette: palette,
        ),
        _SwitchRow(
          icon: Icons.translate,
          title:
              l.settingsShowNativeTranslation(settings.nativeLanguage.displayName),
          subtitle: l.settingsShowNativeTranslationSub,
          value: settings.showNativeHint,
          onChanged: notifier.setShowNativeHint,
          palette: palette,
        ),
        _InlineRow(
          icon: Icons.lightbulb_outline,
          title: l.settingsSuggestionTiming,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<SuggestionMode>(
                segments: [
                  ButtonSegment(
                    value: SuggestionMode.immediate,
                    label: Text(l.settingsSuggestionImmediate),
                    icon: const Icon(Icons.flash_on, size: 16),
                  ),
                  ButtonSegment(
                    value: SuggestionMode.delayed,
                    label: Text(l.settingsSuggestionDelayed),
                    icon: const Icon(Icons.timer_outlined, size: 16),
                  ),
                ],
                selected: {settings.suggestionMode},
                onSelectionChanged: (s) =>
                    notifier.setSuggestionMode(s.first),
                showSelectedIcon: false,
              ),
              if (settings.suggestionMode == SuggestionMode.delayed) ...[
                const SizedBox(height: KFSpacing.x2),
                Row(
                  children: [
                    Text('${settings.suggestionDelaySec}s',
                        style: KFTypography.meta(color: palette.ink3)),
                    Expanded(
                      child: Slider(
                        value: settings.suggestionDelaySec.toDouble(),
                        min: 1,
                        max: 15,
                        divisions: 14,
                        label: '${settings.suggestionDelaySec}s',
                        onChanged: (v) =>
                            notifier.setSuggestionDelay(v.round()),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final KFPalette palette;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.palette,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KFSpacing.x3 + 2, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: palette.beige,
              borderRadius: BorderRadius.circular(KFRadii.xs + 3),
            ),
            child: Icon(icon, size: 16, color: palette.ink),
          ),
          const SizedBox(width: KFSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: KFTypography.body(color: palette.ink).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: KFTypography.meta(color: palette.ink3)
                        .copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ===================
// Group: Voice
// ===================
class _VoiceGroup extends StatelessWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;

  const _VoiceGroup({
    required this.settings,
    required this.notifier,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Group(
      palette: palette,
      children: [
        _SwitchRow(
          icon: Icons.volume_up_outlined,
          title: l.settingsReadTargetAloud(settings.targetLanguage.displayName),
          value: settings.targetTtsEnabled,
          onChanged: notifier.setTargetTtsEnabled,
          palette: palette,
        ),
        _SwitchRow(
          icon: Icons.record_voice_over_outlined,
          title: l.settingsReadTranslationAloud,
          value: settings.nativeTtsEnabled,
          onChanged: notifier.setNativeTtsEnabled,
          palette: palette,
        ),
        _InlineRow(
          icon: Icons.mic_outlined,
          title: l.settingsVoiceGender,
          palette: palette,
          child: SegmentedButton<TtsVoiceGender>(
            segments: [
              ButtonSegment(
                value: TtsVoiceGender.female,
                label: Text(l.settingsVoiceFemale),
              ),
              ButtonSegment(
                value: TtsVoiceGender.male,
                label: Text(l.settingsVoiceMale),
              ),
            ],
            selected: {settings.ttsVoiceGender},
            onSelectionChanged: (s) => notifier.setTtsVoiceGender(s.first),
            showSelectedIcon: false,
          ),
        ),
        _InlineRow(
          icon: Icons.speed_outlined,
          title: l.settingsSpeed,
          subtitle: _speedLabel(l, settings.ttsSpeechRate),
          palette: palette,
          child: Slider(
            value: settings.ttsSpeechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: _speedLabel(l, settings.ttsSpeechRate),
            onChanged: notifier.setTtsSpeechRate,
          ),
        ),
        _InlineRow(
          icon: Icons.timer_outlined,
          title: l.settingsMicPause,
          subtitle: l.settingsMicPauseSub,
          palette: palette,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 3, label: Text(l.settingsMicPauseQuick)),
              ButtonSegment(value: 5, label: Text(l.settingsMicPauseNormal)),
              ButtonSegment(value: 8, label: Text(l.settingsMicPausePatient)),
            ],
            selected: {_nearestPauseOption(settings.sttPauseSeconds)},
            onSelectionChanged: (s) => notifier.setSttPauseSeconds(s.first),
            showSelectedIcon: false,
          ),
        ),
        _SwitchRow(
          icon: Icons.send_outlined,
          title: l.settingsAutoSendVoice,
          subtitle: l.settingsAutoSendVoiceSub,
          value: settings.autoSendVoice,
          onChanged: notifier.setAutoSendVoice,
          palette: palette,
        ),
      ],
    );
  }

  int _nearestPauseOption(int seconds) {
    if (seconds <= 3) return 3;
    if (seconds <= 6) return 5;
    return 8;
  }

  String _speedLabel(AppLocalizations l, double rate) {
    if (rate <= 0.3) return l.settingsSpeedSlow;
    if (rate <= 0.6) return l.settingsSpeedNormal;
    return l.settingsSpeedFast;
  }
}

// ===================
// Group: App
// ===================
class _AppGroup extends ConsumerWidget {
  final UserSettings settings;
  final SettingsNotifier notifier;
  final KFPalette palette;
  final VoidCallback onFeedback;

  const _AppGroup({
    required this.settings,
    required this.notifier,
    required this.palette,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final timeStr =
        '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}';
    return _Group(
      palette: palette,
      children: [
        _SwitchRow(
          icon: Icons.notifications_outlined,
          title: l.settingsDailyReminder,
          subtitle: settings.reminderEnabled
              ? l.settingsDailyReminderOn(timeStr)
              : l.settingsDailyReminderOff,
          value: settings.reminderEnabled,
          onChanged: (v) async {
            await notifier.setReminderEnabled(v);
            if (v) {
              await NotificationService.initialize();
              await NotificationService.scheduleDailyReminder(
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
              );
            } else {
              await NotificationService.cancelAll();
            }
          },
          palette: palette,
        ),
        if (settings.reminderEnabled)
          _Row(
            icon: Icons.access_time,
            title: l.settingsReminderTime,
            detail: timeStr,
            palette: palette,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.reminderHour,
                  minute: settings.reminderMinute,
                ),
              );
              if (picked != null) {
                await notifier.setReminderTime(picked.hour, picked.minute);
                await NotificationService.scheduleDailyReminder(
                  hour: picked.hour,
                  minute: picked.minute,
                );
              }
            },
          ),
        _Row(
          icon: Icons.mail_outline,
          iconTint: palette.sageWash,
          title: l.settingsSendFeedback,
          detail: l.settingsSendFeedbackDetail,
          palette: palette,
          onTap: onFeedback,
        ),
      ],
    );
  }
}
