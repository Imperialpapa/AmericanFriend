import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

const _reply = 'Nice! What did you do next?\n💡 "I goed" → "I went"';

/// 드로어가 열려 있으면 '듣기' 버튼(▶)이 보인다.
final _drawer = find.byIcon(Icons.play_arrow_rounded);

/// ChatScreen 전체는 STT·광고 플러그인을 초기화해서 테스트에서 띄울 수 없다.
/// 대신 _buildMessageList와 같은 규칙(같은 index, 스트리밍/완료 key)으로 말풍선만 그린다.
class _Harness extends StatelessWidget {
  final bool streaming;
  final bool useKeys;
  final bool initialDrawerOpen;
  const _Harness({
    required this.streaming,
    this.useKeys = true,
    this.initialDrawerOpen = true,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = streaming
        ? MessageBubble(
            key: useKeys ? const ValueKey('streaming') : null,
            content: _reply,
            isUser: false,
            initialDrawerOpen: false,
          )
        : MessageBubble(
            key: useKeys ? const ValueKey('1_ai') : null,
            content: _reply,
            isUser: false,
            initialDrawerOpen: initialDrawerOpen,
          );
    return ListView(children: [bubble]);
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        ),
      );

  testWidgets('스트리밍 → 완료 전환 시 최신 AI 답변의 교정 드로어가 탭 없이 열린다',
      (tester) async {
    await pump(tester, const _Harness(streaming: true));
    expect(_drawer, findsNothing);

    await pump(tester, const _Harness(streaming: false));
    expect(_drawer, findsOneWidget);
    expect(find.textContaining('went'), findsOneWidget);
  });

  testWidgets('State가 재사용돼도 initialDrawerOpen false→true면 연다 (didUpdateWidget)',
      (tester) async {
    await pump(tester, const _Harness(streaming: false, initialDrawerOpen: false));
    expect(_drawer, findsNothing);

    await pump(tester, const _Harness(streaming: false, initialDrawerOpen: true));
    expect(_drawer, findsOneWidget);
  });

  testWidgets('key 없이 같은 자리에서 교체돼도 열린다 (예전 버그 경로)', (tester) async {
    await pump(tester, const _Harness(streaming: true, useKeys: false));
    expect(_drawer, findsNothing);

    await pump(tester, const _Harness(streaming: false, useKeys: false));
    expect(_drawer, findsOneWidget);
  });

  testWidgets('true→false는 사용자가 열어 둔 드로어를 닫지 않는다', (tester) async {
    await pump(tester, const _Harness(streaming: false, initialDrawerOpen: true));
    expect(_drawer, findsOneWidget);

    await pump(tester, const _Harness(streaming: false, initialDrawerOpen: false));
    expect(_drawer, findsOneWidget);
  });
}
