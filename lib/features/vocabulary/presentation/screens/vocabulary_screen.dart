import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabState = ref.watch(vocabularyProvider);
    final l = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.vocabTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.vocabTabAll(vocabState.allItems.length)),
              Tab(text: l.vocabTabReview(vocabState.dueItems.length)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context, ref),
          child: const Icon(Icons.add),
        ),
        body: vocabState.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _WordList(items: vocabState.allItems),
                  // 빈 상태 분기는 _ReviewCards 안에 있다. 세션 도중 due 목록이 비어도
                  // '다시'로 큐 뒤에 돌려놓은 카드는 끝까지 보여야 하기 때문.
                  _ReviewCards(items: vocabState.dueItems),
                ],
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final expressionCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.vocabAddTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: expressionCtrl,
              decoration: InputDecoration(
                labelText: l.vocabFieldExpression,
                hintText: l.vocabFieldExpressionHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: meaningCtrl,
              decoration: InputDecoration(
                labelText: l.vocabFieldMeaning,
                hintText: l.vocabFieldMeaningHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (expressionCtrl.text.trim().isNotEmpty) {
                ref.read(vocabularyProvider.notifier).addWord(
                      expression: expressionCtrl.text.trim(),
                      meaning: meaningCtrl.text.trim(),
                    );
                Navigator.pop(dctx);
              }
            },
            child: Text(l.vocabButtonAdd),
          ),
        ],
      ),
    );
  }
}

class _WordList extends ConsumerWidget {
  final List<VocabularyItem> items;
  const _WordList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).vocabListEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            final notifier = ref.read(vocabularyProvider.notifier);
            final l = AppLocalizations.of(context);
            notifier.deleteWord(item.id);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(l.vocabDeleted(item.expression)),
                action: SnackBarAction(
                  label: l.commonUndo,
                  onPressed: () => notifier.restoreWord(item),
                ),
              ));
          },
          child: Card(
            child: ListTile(
              title: Text(
                item.expression,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: item.meaning.isNotEmpty ? Text(item.meaning) : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: _statusColor(item),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.intervalDays}d',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(VocabularyItem item) {
    if (item.correctCount >= 5) return Colors.green;
    if (item.correctCount >= 2) return Colors.orange;
    return Colors.red;
  }
}

class _ReviewCards extends ConsumerStatefulWidget {
  final List<VocabularyItem> items;
  const _ReviewCards({required this.items});

  @override
  ConsumerState<_ReviewCards> createState() => _ReviewCardsState();
}

class _ReviewCardsState extends ConsumerState<_ReviewCards> {
  /// 세션 시작 시점의 due 목록 스냅샷. review()가 due 목록을 줄여도 큐는 그대로라서
  /// 인덱스가 어긋나지 않는다 (예전엔 A → C → E로 한 장씩 건너뜀, BUG #11).
  late List<VocabularyItem> _queue;

  /// 이 세션 큐에 한 번이라도 들어간 id — 새로 due가 된 단어만 골라내는 데 쓴다.
  final Set<int> _seenIds = {};
  int _index = 0;
  bool _showMeaning = false;

  @override
  void initState() {
    super.initState();
    _queue = List.of(widget.items);
    _seenIds.addAll(_queue.map((i) => i.id));
  }

  @override
  void didUpdateWidget(covariant _ReviewCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    // + 버튼으로 새 단어가 due가 되면: 복습 중이면 큐 뒤에 붙이고, 끝났거나 비어 있었으면
    // 새 세션으로 시작한다. 이미 본 단어는 review() 반영 전 목록이 와도 다시 넣지 않는다.
    final fresh = [
      for (final i in widget.items)
        if (!_seenIds.contains(i.id)) i,
    ];
    if (fresh.isEmpty) return;
    _seenIds.addAll(fresh.map((i) => i.id));
    if (_index >= _queue.length) {
      _queue = fresh;
      _index = 0;
      _showMeaning = false;
    } else {
      _queue.addAll(fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            Text(l.vocabCaughtUp),
            Text(
              l.vocabCaughtUpSub,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (_index >= _queue.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(l.vocabReviewComplete,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final item = _queue[_index];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 진행률
          LinearProgressIndicator(
            value: _index / _queue.length,
            borderRadius: BorderRadius.circular(4),
          ),
          Text(
            '${_index + 1} / ${_queue.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const Spacer(),

          // 카드
          Card(
            elevation: 4,
            child: InkWell(
              onTap: () => setState(() => _showMeaning = !_showMeaning),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      item.expression,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_showMeaning && item.meaning.isNotEmpty)
                      Text(
                        item.meaning,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        l.vocabReviewTapReveal,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // 정답/오답 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: () => _answer(item, correct: false),
                icon: const Icon(Icons.close),
                label: Text(l.vocabReviewAgain),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(140, 48),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _answer(item, correct: true),
                icon: const Icon(Icons.check),
                label: Text(l.vocabReviewGotIt),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size(140, 48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _answer(VocabularyItem item, {required bool correct}) {
    ref.read(vocabularyProvider.notifier).review(item.id, correct: correct);
    setState(() {
      // '다시'는 이번 세션 끝에 한 번 더 — 하루 뒤로 미루기만 하면 틀린 단어를 다시 못 본다.
      if (!correct) _queue.add(item);
      _index++;
      _showMeaning = false;
    });
  }
}
