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
    await _db.deleteVocabulary(itemId);
    await refresh();
  }
}

final vocabularyProvider =
    StateNotifierProvider<VocabularyNotifier, VocabularyState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VocabularyNotifier(db);
});
