import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

VocabularyItem _word(int id) => VocabularyItem(
      id: id,
      expression: 'word$id',
      meaning: '',
      example: '',
      nextReviewAt: DateTime(2026),
      intervalDays: 1,
      correctCount: 0,
      createdAt: DateTime(2026),
    );

// LazyDatabase라 쿼리를 날리기 전엔 열리지 않는다. 테스트마다 만들면 drift가 중복 경고를 낸다.
final _unopenedDb = AppDatabase();

/// DB 없이 실제와 같은 부수효과만 흉내 낸다: review()가 끝나면 그 단어가 due 목록에서 빠진다.
/// (이 축소가 예전 인덱스 순회를 한 칸씩 건너뛰게 만든 원인 — BUG #11)
class _FakeVocabulary extends VocabularyNotifier {
  _FakeVocabulary(List<VocabularyItem> due) : super(_unopenedDb) {
    state = VocabularyState(allItems: due, dueItems: due, loading: false);
  }

  final reviewed = <(int, bool)>[];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> review(int itemId, {required bool correct}) async {
    reviewed.add((itemId, correct));
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(
      dueItems: state.dueItems.where((i) => i.id != itemId).toList(),
    );
  }
}

Future<_FakeVocabulary> _pumpReviewTab(WidgetTester tester, int count) async {
  final fake = _FakeVocabulary([for (var i = 1; i <= count; i++) _word(i)]);
  await tester.pumpWidget(ProviderScope(
    overrides: [vocabularyProvider.overrideWith((ref) => fake)],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VocabularyScreen(),
    ),
  ));
  await tester.tap(find.text('Review ($count)'));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('due 6장이 모두 순서대로 나온다 (건너뛰지 않음)', (tester) async {
    final fake = await _pumpReviewTab(tester, 6);

    for (var i = 1; i <= 6; i++) {
      expect(find.text('word$i'), findsOneWidget, reason: 'card $i');
      expect(find.text('$i / 6'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Review complete!'), findsOneWidget);
    expect(fake.reviewed.map((r) => r.$1), [1, 2, 3, 4, 5, 6]);
  });

  testWidgets("'다시'를 누른 카드는 큐 끝(7번째)에 다시 나온다", (tester) async {
    final fake = await _pumpReviewTab(tester, 6);

    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    for (var i = 2; i <= 6; i++) {
      expect(find.text('word$i'), findsOneWidget, reason: 'card $i');
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }

    // due 목록은 이미 비었지만 세션은 재삽입된 카드를 끝까지 보여 준다
    expect(fake.state.dueItems, isEmpty);
    expect(find.text('word1'), findsOneWidget);
    expect(find.text('7 / 7'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Review complete!'), findsOneWidget);
    expect(fake.reviewed.first, (1, false));
    expect(fake.reviewed.last, (1, true));
  });

  testWidgets('due가 없으면 빈 상태를 보여 준다', (tester) async {
    await _pumpReviewTab(tester, 0);
    expect(find.text('All caught up!'), findsOneWidget);
  });
}
