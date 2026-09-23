import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

void main() {
  group('parsePolicyText', () {
    test('HTML 주석(DRAFT 표시)은 내보내지 않고 제목·목록·문단을 나눈다', () {
      final blocks = parsePolicyText('''
<!-- DRAFT: 사용자 법률 검토 필요 -->
# Title

Intro line.
## Section
### Sub
- item one
<!--
multi-line
-->
- item two
''');
      expect(blocks.map((b) => b.kind), [
        PolicyBlockKind.h1,
        PolicyBlockKind.paragraph,
        PolicyBlockKind.h2,
        PolicyBlockKind.h3,
        PolicyBlockKind.bullet,
        PolicyBlockKind.bullet,
      ]);
      expect(blocks.map((b) => b.text).join('\n'), isNot(contains('DRAFT')));
      expect(blocks.map((b) => b.text).join('\n'), isNot(contains('multi-line')));
      expect(blocks.last.text, 'item two');
    });
  });

  for (final lang in ['ko', 'en']) {
    test('번들 처리방침($lang): 첫 줄이 DRAFT 표시이고, 핵심 고지가 들어 있다', () {
      final raw = File('assets/legal/privacy_$lang.md').readAsStringSync();
      expect(raw.split('\n').first.trim(), '<!-- DRAFT: 사용자 법률 검토 필요 -->');
      final text = parsePolicyText(raw).map((b) => b.text).join('\n');
      for (final fact in [
        'Vercel',
        'Upstash',
        'Groq',
        'Anthropic',
        'OpenAI',
        'AdMob',
        '48',
        '2,000',
        'raphael70kim@gmail.com',
      ]) {
        expect(text, contains(fact), reason: '$lang policy missing "$fact"');
      }
    });
  }

  testWidgets('처리방침 화면이 번들 텍스트를 그리고 DRAFT 줄은 숨긴다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrivacyPolicyScreen(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Korean Friend Privacy Policy'), findsOneWidget);
    expect(find.textContaining('DRAFT'), findsNothing);
  });
}
