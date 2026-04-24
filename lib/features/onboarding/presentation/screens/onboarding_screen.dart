import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/language/app_language.dart';

const _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;
  static const _totalPages = 3;

  int _selectedLevel = LevelConstants.defaultLevel;
  late AppLanguage _nativeLanguage;
  late AppLanguage _targetLanguage;
  AiProviderType _onboardingProvider = AiProviderType.gemini;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _nativeLanguage = AppLanguage.fromSystemLocale(systemLocale);
    _targetLanguage = _nativeLanguage == AppLanguage.englishUS ||
            _nativeLanguage == AppLanguage.englishUK
        ? AppLanguage.korean
        : AppLanguage.englishUS;
    _apiKeyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(palette),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _pageContent(palette),
              ),
            ),
            _ctaSection(palette),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  // ===== Shared chrome =====

  Widget _topBar(KFPalette palette) {
    final showSkip = _currentPage > 0 && _currentPage < _totalPages - 1;
    final showBack = _currentPage > 0;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x3, KFSpacing.x4, KFSpacing.x5, KFSpacing.x2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: showBack
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: palette.ink2),
                    tooltip: l.commonBack,
                    onPressed: () =>
                        setState(() => _currentPage = _currentPage - 1),
                  )
                : null,
          ),
          const SizedBox(width: KFSpacing.x2),
          _StepDots(step: _currentPage, total: _totalPages),
          const Spacer(),
          if (showSkip)
            TextButton(
              onPressed: () => setState(() => _currentPage = _totalPages - 1),
              child: Text(
                l.commonSkip,
                style: KFTypography.meta(color: palette.ink3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ctaSection(KFPalette palette) {
    final l = AppLocalizations.of(context);
    final cta = _ctaForPage();
    return Container(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x5, KFSpacing.x2, KFSpacing.x5, KFSpacing.x4),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(
          top: BorderSide(color: palette.hairline, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: cta.enabled ? cta.onTap : null,
              child: Opacity(
                opacity: cta.enabled ? 1 : 0.4,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.sage,
                    borderRadius: KFRadii.rMd,
                    boxShadow: cta.enabled ? KFShadows.sageCta : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cta.label,
                        style: KFTypography.body(color: Colors.white).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            l.onboardStepOf(_currentPage + 1, _totalPages),
            style: KFTypography.tiny(color: palette.ink3).copyWith(
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _CtaSpec _ctaForPage() {
    final l = AppLocalizations.of(context);
    switch (_currentPage) {
      case 0:
        return _CtaSpec(
          label: l.onboardCtaLetsGo,
          enabled: true,
          onTap: () => setState(() => _currentPage = 1),
        );
      case 1:
        return _CtaSpec(
          label: l.commonContinue,
          enabled: _nativeLanguage != _targetLanguage,
          onTap: _saveLanguagesAndContinue,
        );
      case 2:
        return _CtaSpec(
          label: l.onboardCtaStartChatting,
          enabled: true,
          onTap: _complete,
        );
    }
    return _CtaSpec(label: l.commonContinue, enabled: false, onTap: () {});
  }

  Widget _pageContent(KFPalette palette) {
    switch (_currentPage) {
      case 0:
        return _welcomePage(palette);
      case 1:
        return _languagePage(palette);
      case 2:
        return _levelPage(palette);
    }
    return const SizedBox.shrink();
  }

  // ===== Page 1: Welcome =====
  Widget _welcomePage(KFPalette palette) {
    final l = AppLocalizations.of(context);
    final welcome = l.chatWelcomeTitle(AppConstants.aiCharacterName);
    // 이름만 sage 색상으로 강조
    final nameIdx = welcome.indexOf(AppConstants.aiCharacterName);
    final beforeName =
        nameIdx >= 0 ? welcome.substring(0, nameIdx) : welcome;
    final afterName = nameIdx >= 0
        ? welcome.substring(nameIdx + AppConstants.aiCharacterName.length)
        : '';
    return SingleChildScrollView(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x6),
      child: Column(
        children: [
          const SizedBox(height: KFSpacing.x10),
          const AlexAvatar(size: 120, emotion: AlexEmotion.celebrate),
          const SizedBox(height: KFSpacing.x6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: beforeName,
                  style: KFTypography.h1(color: palette.ink),
                ),
                TextSpan(
                  text: AppConstants.aiCharacterName,
                  style: KFTypography.h1(color: palette.sageDeep),
                ),
                if (afterName.isNotEmpty)
                  TextSpan(
                    text: afterName,
                    style: KFTypography.h1(color: palette.ink),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KFSpacing.x3),
          Text(
            l.onboardWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: KFTypography.body(color: palette.ink2).copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Page 2: Language =====
  Widget _languagePage(KFPalette palette) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey('language'),
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: KFSpacing.x4),
          _AlexBubble(
            text: l.onboardLanguageBubble,
            emotion: AlexEmotion.thinking,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x5),
          _Headline(
            normalPart: l.onboardLanguageHeadline1,
            accentPart: l.onboardLanguageHeadline2,
            suffix: l.onboardLanguageHeadline3,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            l.onboardLanguageHelp,
            style: KFTypography.meta(color: palette.ink2).copyWith(
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: KFSpacing.x6),

          _SectionLabel(
              text: l.onboardLanguageNativeLabel, palette: palette),
          const SizedBox(height: KFSpacing.x2),
          _LanguageDropdown(
            value: _nativeLanguage,
            icon: Icons.translate,
            palette: palette,
            onChanged: (lang) {
              if (lang != null) setState(() => _nativeLanguage = lang);
            },
          ),

          const SizedBox(height: KFSpacing.x5),

          _SectionLabel(
              text: l.onboardLanguageTargetLabel, palette: palette),
          const SizedBox(height: KFSpacing.x2),
          _LanguageDropdown(
            value: _targetLanguage,
            icon: Icons.school_outlined,
            palette: palette,
            onChanged: (lang) {
              if (lang != null) setState(() => _targetLanguage = lang);
            },
          ),

          if (_nativeLanguage == _targetLanguage) ...[
            const SizedBox(height: KFSpacing.x3),
            Container(
              padding: const EdgeInsets.all(KFSpacing.x3),
              decoration: BoxDecoration(
                color: palette.coral.withValues(alpha: 0.12),
                borderRadius: KFRadii.rMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: palette.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.onboardLanguageMustDiffer,
                      style: KFTypography.meta(color: palette.coral),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== (보존) BYOK 온보딩 필요 시 복원용 =====
  // ignore: unused_element
  Widget _apiKeyPage(KFPalette palette) {
    final l = AppLocalizations.of(context);
    final keyUrl = _onboardingProvider == AiProviderType.gemini
        ? 'https://aistudio.google.com/apikey'
        : 'https://console.groq.com/keys';

    return SingleChildScrollView(
      key: const ValueKey('apikey'),
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: KFSpacing.x4),
          _AlexBubble(
            text: l.onboardApiBubble,
            emotion: AlexEmotion.calm,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x5),
          _Headline(
            normalPart: l.onboardApiHeadline1,
            accentPart: l.onboardApiHeadline2,
            suffix: l.onboardApiHeadline3,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            l.onboardApiHelp,
            style: KFTypography.meta(color: palette.ink2).copyWith(fontSize: 13),
          ),
          const SizedBox(height: KFSpacing.x5),

          // Provider selector
          _ProviderSegment(
            value: _onboardingProvider,
            palette: palette,
            onChanged: (v) => setState(() => _onboardingProvider = v),
          ),
          const SizedBox(height: KFSpacing.x2),
          Text(
            _onboardingProvider == AiProviderType.gemini
                ? l.onboardApiGeminiDesc
                : l.onboardApiGroqDesc,
            style: KFTypography.meta(color: palette.ink3).copyWith(fontSize: 12),
          ),

          const SizedBox(height: KFSpacing.x5),

          _StepCard(
            step: '1',
            title: l.onboardApiStep1Title,
            subtitle: keyUrl,
            palette: palette,
            action: _SecondaryButton(
              icon: Icons.open_in_new_rounded,
              label: l.onboardApiStep1Action,
              palette: palette,
              onTap: () => _launchUrl(keyUrl),
            ),
          ),
          const SizedBox(height: KFSpacing.x3),
          _StepCard(
            step: '2',
            title: l.onboardApiStep2Title,
            subtitle: l.onboardApiStep2Sub,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x3),
          _StepCard(
            step: '3',
            title: l.onboardApiStep3Title,
            palette: palette,
            action: _ApiKeyField(
              controller: _apiKeyController,
              palette: palette,
              hintText: l.onboardApiKeyHint,
              pasteTooltip: l.onboardApiPaste,
              onPaste: _pasteFromClipboard,
            ),
          ),
          const SizedBox(height: KFSpacing.x3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x2),
            child: Text(
              l.onboardApiFreeTierHint,
              textAlign: TextAlign.center,
              style: KFTypography.meta(color: palette.ink3).copyWith(
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Page 4: Level =====
  Widget _levelPage(KFPalette palette) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey('level'),
      padding: const EdgeInsets.symmetric(horizontal: KFSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: KFSpacing.x4),
          _AlexBubble(
            text: l.onboardLevelBubble,
            emotion: AlexEmotion.listening,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x5),
          _Headline(
            normalPart: l.onboardLevelHeadline1,
            accentPart: l.onboardLevelHeadline2,
            suffix: l.onboardLevelHeadline3,
            palette: palette,
          ),
          const SizedBox(height: KFSpacing.x6),

          // Big level display
          Center(
            child: Column(
              children: [
                Text(
                  '$_selectedLevel',
                  style: KFTypography.display(color: palette.ink).copyWith(
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: KFSpacing.x2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.sageWash,
                    borderRadius: KFRadii.rFull,
                  ),
                  child: Text(
                    LevelConstants.levelNames[_selectedLevel],
                    style: KFTypography.meta(color: palette.sageDeep).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KFSpacing.x6),
          Slider(
            value: _selectedLevel.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_selectedLevel',
            onChanged: (v) => setState(() => _selectedLevel = v.round()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.onboardLevelBeginner,
                    style: KFTypography.tiny(color: palette.ink3)),
                Text(l.onboardLevelNative,
                    style: KFTypography.tiny(color: palette.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Actions =====
  Future<void> _saveLanguagesAndContinue() async {
    if (_nativeLanguage == _targetLanguage) return;
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setNativeLanguage(_nativeLanguage);
    await notifier.setTargetLanguage(_targetLanguage);
    setState(() => _currentPage = 2);
  }

  // ignore: unused_element
  Future<void> _saveKeyAndContinue() async {
    final key = _apiKeyController.text.trim();
    final notifier = ref.read(settingsProvider.notifier);

    if (key.isEmpty) {
      // 키 없음 → free tier (프록시)로 시작
      await notifier.setAiProvider(AiProviderType.freeTier);
    } else {
      await notifier.setAiProvider(_onboardingProvider);
      if (_onboardingProvider == AiProviderType.gemini) {
        await notifier.setGeminiApiKey(key);
      } else {
        await notifier.setGroqApiKey(key);
      }
    }
    if (mounted) setState(() => _currentPage = 3);
  }

  Future<void> _complete() async {
    await ref.read(levelProvider.notifier).setLevel(_selectedLevel);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingCompleteKey, true);
    widget.onComplete();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _apiKeyController.text = text;
    }
  }
}

// ===== Sub-widgets =====

class _CtaSpec {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _CtaSpec(
      {required this.label, required this.enabled, required this.onTap});
}

class _StepDots extends StatelessWidget {
  final int step;
  final int total;
  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
          height: 4,
          width: i == step ? 22 : 6,
          decoration: BoxDecoration(
            color: i <= step ? palette.sage : palette.hairline,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _AlexBubble extends StatelessWidget {
  final String text;
  final AlexEmotion emotion;
  final KFPalette palette;

  const _AlexBubble({
    required this.text,
    required this.emotion,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AlexAvatar(size: 56, emotion: emotion),
        const SizedBox(width: KFSpacing.x3),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KFSpacing.x3, vertical: 12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: KFRadii.aiBubble,
              border: Border.all(color: palette.hairline, width: 1),
              boxShadow: isDark ? null : KFShadows.card,
            ),
            child: Text(
              text,
              style: KFTypography.body(color: palette.ink).copyWith(
                fontSize: 14,
                height: 1.45,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  final String normalPart;
  final String accentPart;
  final String suffix;
  final KFPalette palette;

  const _Headline({
    required this.normalPart,
    required this.accentPart,
    required this.suffix,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final base = KFTypography.h1(color: palette.ink).copyWith(
      fontSize: 30,
      height: 1.15,
      letterSpacing: -0.6,
    );
    final accent = base.copyWith(color: palette.sageDeep);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: normalPart, style: base),
        TextSpan(text: accentPart, style: accent),
        TextSpan(text: suffix, style: base),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final KFPalette palette;
  const _SectionLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: KFTypography.tiny(color: palette.ink3).copyWith(
        letterSpacing: 0.8,
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final AppLanguage value;
  final IconData icon;
  final KFPalette palette;
  final ValueChanged<AppLanguage?> onChanged;

  const _LanguageDropdown({
    required this.value,
    required this.icon,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: KFRadii.rMd,
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.ink2),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.expand_more, color: palette.ink3),
                style: KFTypography.body(color: palette.ink).copyWith(
                  fontSize: 15,
                ),
                dropdownColor: palette.card,
                items: AppLanguage.values
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang.label),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSegment extends StatelessWidget {
  final AiProviderType value;
  final KFPalette palette;
  final ValueChanged<AiProviderType> onChanged;

  const _ProviderSegment({
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.beige,
        borderRadius: KFRadii.rMd,
      ),
      child: Row(
        children: [
          _segment(AiProviderType.gemini, 'Gemini', Icons.auto_awesome),
          _segment(AiProviderType.groq, 'Groq', Icons.bolt),
        ],
      ),
    );
  }

  Widget _segment(AiProviderType v, String label, IconData icon) {
    final selected = value == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? palette.card : Colors.transparent,
            borderRadius: KFRadii.rSm,
            boxShadow: selected ? KFShadows.card : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? palette.sageDeep : palette.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: KFTypography.body(
                  color: selected ? palette.ink : palette.ink2,
                ).copyWith(
                  fontSize: 14,
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

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String? subtitle;
  final Widget? action;
  final KFPalette palette;

  const _StepCard({
    required this.step,
    required this.title,
    required this.palette,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KFSpacing.x3),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: KFRadii.rLg,
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.sage,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: KFTypography.body(color: Colors.white).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KFTypography.body(color: palette.ink).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: KFTypography.meta(color: palette.ink3)
                            .copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: KFSpacing.x3),
            SizedBox(width: double.infinity, child: action!),
          ],
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final KFPalette palette;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KFRadii.rSm,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: palette.beige,
            borderRadius: KFRadii.rSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: palette.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: KFTypography.body(color: palette.ink).copyWith(
                  fontSize: 13,
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

class _ApiKeyField extends StatelessWidget {
  final TextEditingController controller;
  final KFPalette palette;
  final VoidCallback onPaste;
  final String hintText;
  final String pasteTooltip;

  const _ApiKeyField({
    required this.controller,
    required this.palette,
    required this.onPaste,
    required this.hintText,
    required this.pasteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.beige,
        borderRadius: KFRadii.rSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: KFTypography.body(color: palette.ink3).copyWith(
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                isDense: true,
              ),
              style: KFTypography.body(color: palette.ink).copyWith(
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_paste_rounded, color: palette.ink2),
            tooltip: pasteTooltip,
            onPressed: onPaste,
          ),
        ],
      ),
    );
  }
}
