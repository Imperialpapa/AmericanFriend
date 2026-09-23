import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

class VocabularyState {
  final List<VocabularyItem> allItems;
  final List<VocabularyItem> dueItems;
  final bool loading;

  const VocabularyState({
    this.allItems = const [],
    this.dueItems = const [],
    this.loading = true,
  });

  VocabularyState copyWith({
    List<VocabularyItem>? allItems,
    List<VocabularyItem>? dueItems,
    bool? loading,
  }) {
    return VocabularyState(
      allItems: allItems ?? this.allItems,
      dueItems: dueItems ?? this.dueItems,
      loading: loading ?? this.loading,
    );
  }
}

class VocabularyNotifier extends StateNotifier<VocabularyState> {
  final AppDatabase _db;

  VocabularyNotifier(this._db) : super(const VocabularyState()) {
    refresh();
  }

  Future<void> refresh() async {
    final all = await _db.getAllVocabulary();
    final due = await _db.getDueVocabulary();
    state = VocabularyState(allItems: all, dueItems: due, loading: false);
  }

  Future<void> addWord({
    required String expression,
    String meaning = '',
    String example = '',
  }) async {
    await _db.addVocabularyItem(
      expression: expression,
      meaning: meaning,
      example: example,
    );
    await refresh();
  }

  Future<void> review(int itemId, {required bool correct}) async {
    await _db.reviewVocabulary(itemId, correct: correct);
    await refresh();
  }

  Future<void> deleteWord(int itemId) async {
    // Dismissible은 onDismissed 직후 목록에서 빠져 있어야 한다. DB 왕복을 기다리는
    // 사이에 리빌드되면 "dismissed Dismissible is still part of the tree"가 난다.
    state = state.copyWith(
      allItems: state.allItems.where((i) => i.id != itemId).toList(),
      dueItems: state.dueItems.where((i) => i.id != itemId).toList(),
    );
    await _db.deleteVocabulary(itemId);
    await refresh();
  }

  /// 스와이프 삭제 실행 취소
  Future<void> restoreWord(VocabularyItem item) async {
    await _db.restoreVocabularyItem(item);
    await refresh();
  }
}

final vocabularyProvider =
    StateNotifierProvider<VocabularyNotifier, VocabularyState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VocabularyNotifier(db);
});
