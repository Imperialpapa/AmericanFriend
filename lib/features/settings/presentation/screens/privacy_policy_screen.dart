import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

enum PolicyBlockKind { h1, h2, h3, bullet, paragraph }

class PolicyBlock {
  final PolicyBlockKind kind;
  final String text;
  const PolicyBlock(this.kind, this.text);
}

/// 번들된 처리방침을 제목·목록·문단으로 나눈다. 마크다운 의존성 없이 쓰는 최소 규칙.
/// HTML 주석(맨 윗줄 `<!-- DRAFT ... -->` 등)은 화면에 내보내지 않는다.
List<PolicyBlock> parsePolicyText(String raw) {
  final blocks = <PolicyBlock>[];
  var inComment = false;
  for (final line in const LineSplitter().convert(raw)) {
    final t = line.trim();
    if (inComment) {
      if (t.contains('-->')) inComment = false;
      continue;
    }
    if (t.startsWith('<!--')) {
      inComment = !t.contains('-->');
      continue;
    }
    if (t.isEmpty) continue;
    final block = t.startsWith('### ')
        ? PolicyBlock(PolicyBlockKind.h3, t.substring(4))
        : t.startsWith('## ')
            ? PolicyBlock(PolicyBlockKind.h2, t.substring(3))
            : t.startsWith('# ')
                ? PolicyBlock(PolicyBlockKind.h1, t.substring(2))
                : t.startsWith('- ')
                    ? PolicyBlock(PolicyBlockKind.bullet, t.substring(2))
                    : PolicyBlock(PolicyBlockKind.paragraph, t);
    blocks.add(block);
  }
  return blocks;
}

/// 한국어 UI면 한국어 원문, 그 밖에는 영어.
String privacyPolicyAssetFor(Locale locale) => locale.languageCode == 'ko'
    ? 'assets/legal/privacy_ko.md'
    : 'assets/legal/privacy_en.md';

/// Play User Data 정책: 처리방침은 앱 안에서도 볼 수 있어야 한다(tobe P-02).
/// 오프라인에서도 열리도록 번들 텍스트를 보여 주고, 공개 URL이 있으면 링크를 덧붙인다.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<List<PolicyBlock>>? _blocks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _blocks ??= rootBundle
        .loadString(privacyPolicyAssetFor(Localizations.localeOf(context)))
        .then(parsePolicyText);
  }

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: Text(l.settingsPrivacyPolicy)),
      body: FutureBuilder<List<PolicyBlock>>(
        future: _blocks,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(KFSpacing.x6),
                child: Text(l.privacyPolicyLoadFailed,
                    textAlign: TextAlign.center,
                    style: KFTypography.body(color: palette.ink2)),
              ),
            );
          }
          final blocks = snap.data;
          if (blocks == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  KFSpacing.x5, KFSpacing.x3, KFSpacing.x5, KFSpacing.x10),
              children: [
                if (AppConstants.privacyPolicyUrl.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(AppConstants.privacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(l.privacyPolicyOpenInBrowser),
                    ),
                  ),
                for (final b in blocks) _block(palette, b),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _block(KFPalette palette, PolicyBlock b) {
    final body = KFTypography.bodyR(color: palette.ink2).copyWith(height: 1.55);
    return switch (b.kind) {
      PolicyBlockKind.h1 => Padding(
          padding: const EdgeInsets.only(bottom: KFSpacing.x2),
          child: Text(b.text, style: KFTypography.h1(color: palette.ink)),
        ),
      PolicyBlockKind.h2 => Padding(
          padding: const EdgeInsets.only(top: KFSpacing.x5, bottom: KFSpacing.x2),
          child: Text(b.text, style: KFTypography.h2(color: palette.ink)),
        ),
      PolicyBlockKind.h3 => Padding(
          padding: const EdgeInsets.only(top: KFSpacing.x3, bottom: KFSpacing.x1),
          child: Text(b.text,
              style: KFTypography.body(color: palette.ink)
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
      PolicyBlockKind.bullet => Padding(
          padding: const EdgeInsets.only(left: KFSpacing.x1, bottom: KFSpacing.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: body),
              Expanded(child: Text(b.text, style: body)),
            ],
          ),
        ),
      PolicyBlockKind.paragraph => Padding(
          padding: const EdgeInsets.only(bottom: KFSpacing.x2),
          child: Text(b.text, style: body),
        ),
    };
  }
}
