import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, Widget bubble) => tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ListView(children: [bubble])),
          ),
        ),
      );

  testWidgets('롱프레스 → 응답 신고 → 사유 선택이면 말풍선에 신고됨 표시', (tester) async {
    await pump(
      tester,
      const MessageBubble(
        key: ValueKey('a1'),
        content: 'Paris is in Germany.',
        isUser: false,
        messageId: 'a1',
        prevUserText: 'Where is Paris?',
      ),
    );

    await tester.longPress(find.text('Paris is in Germany.'));
    await tester.pumpAndSettle();
    expect(find.text('Save to vocabulary'), findsOneWidget);
    await tester.tap(find.text('Report response'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Incorrect or misleading'));
    await tester.pumpAndSettle();

    // 테스트에선 설정이 로드되지 않아 기기 id가 비어 있다 → 큐에 들어간다.
    expect(find.textContaining("We'll retry"), findsOneWidget);
    expect(find.text('Reported'), findsOneWidget);
    expect(prefs.getString('pending_ai_reports'), contains('Where is Paris?'));
  });

  testWidgets('스트리밍 말풍선(id 없음)은 신고 버튼이 없고 롱프레스는 바로 저장 창',
      (tester) async {
    await pump(
      tester,
      const MessageBubble(
        key: ValueKey('streaming'),
        content: 'Hello there',
        isUser: false,
        initialDrawerOpen: true,
      ),
    );
    expect(find.byIcon(Icons.flag_outlined), findsNothing);

    await tester.longPress(find.text('Hello there'));
    await tester.pumpAndSettle();
    expect(find.text('Report response'), findsNothing);
    expect(find.text('Save to Vocabulary'), findsOneWidget);
  });

  testWidgets('저장된 말풍선의 드로어에는 신고 버튼이 있다', (tester) async {
    await pump(
      tester,
      const MessageBubble(
        key: ValueKey('a2'),
        content: 'Hello there',
        isUser: false,
        initialDrawerOpen: true,
        messageId: 'a2',
      ),
    );
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.byTooltip('Report response'), findsOneWidget);
  });
}
