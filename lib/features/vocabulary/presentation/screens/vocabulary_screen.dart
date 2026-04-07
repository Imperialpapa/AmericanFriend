import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/vocabulary/presentation/providers/vocabulary_provider.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabState = ref.watch(vocabularyProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Vocabulary'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'All (${vocabState.allItems.length})'),
              Tab(text: 'Review (${vocabState.dueItems.length})'),
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
                  vocabState.dueItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 48, color: Colors.green),
                              SizedBox(height: 8),
                              Text('All caught up!'),
                              Text(
                                'No words to review right now.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : _ReviewCards(items: vocabState.dueItems),
                ],
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final expressionCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: expressionCtrl,
              decoration: const InputDecoration(
                labelText: 'Expression',
                hintText: 'e.g. break the ice',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: meaningCtrl,
              decoration: const InputDecoration(
                labelText: 'Meaning',
                hintText: 'e.g. to start a conversation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (expressionCtrl.text.trim().isNotEmpty) {
                ref.read(vocabularyProvider.notifier).addWord(
                      expression: expressionCtrl.text.trim(),
                      meaning: meaningCtrl.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
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
      return const Center(
        child: Text(
          'No words saved yet.\nLong-press text in chat or tap + to add.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
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
            ref.read(vocabularyProvider.notifier).deleteWord(item.id);
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
  int _currentIndex = 0;
  bool _showMeaning = false;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.items.length) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 48, color: Colors.amber),
            SizedBox(height: 8),
            Text('Review complete!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final item = widget.items[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 진행률
          LinearProgressIndicator(
            value: _currentIndex / widget.items.length,
            borderRadius: BorderRadius.circular(4),
          ),
          Text(
            '${_currentIndex + 1} / ${widget.items.length}',
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
                        'Tap to reveal',
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
                onPressed: () => _answer(item.id, correct: false),
                icon: const Icon(Icons.close),
                label: const Text('Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(140, 48),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _answer(item.id, correct: true),
                icon: const Icon(Icons.check),
                label: const Text('Got it'),
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

  void _answer(int itemId, {required bool correct}) {
    ref.read(vocabularyProvider.notifier).review(itemId, correct: correct);
    setState(() {
      _currentIndex++;
      _showMeaning = false;
    });
  }
}
