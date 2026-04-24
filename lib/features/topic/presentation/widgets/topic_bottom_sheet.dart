import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/topic/domain/entities/topic.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

String _categoryLocalized(AppLocalizations l, TopicCategory cat) =>
    switch (cat) {
      TopicCategory.daily => l.topicCategoryDaily,
      TopicCategory.travel => l.topicCategoryTravel,
      TopicCategory.food => l.topicCategoryFood,
      TopicCategory.work => l.topicCategoryWork,
      TopicCategory.shopping => l.topicCategoryShopping,
      TopicCategory.health => l.topicCategoryHealth,
      TopicCategory.social => l.topicCategorySocial,
      TopicCategory.entertainment => l.topicCategoryEntertainment,
    };

/// 주제 선택 바텀시트
class TopicBottomSheet extends ConsumerWidget {
  const TopicBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TopicBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicState = ref.watch(topicProvider);
    final todaysTopic = ref.read(topicProvider.notifier).todaysTopic;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.topic, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).topicSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 오늘의 추천 주제
                  _TodaysTopicCard(
                    topic: todaysTopic,
                    isActive: topicState.activeTopic?.id == todaysTopic.id,
                  ),
                  const SizedBox(height: 16),

                  // 카테고리별 주제 목록
                  ...TopicCategory.values.map((category) {
                    final topics = TopicCatalog.byCategory(category);
                    return _CategorySection(
                      category: category,
                      topics: topics,
                      activeTopicId: topicState.activeTopic?.id,
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TodaysTopicCard extends ConsumerWidget {
  final Topic topic;
  final bool isActive;

  const _TodaysTopicCard({required this.topic, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Card(
      color: Colors.orange.shade900,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive
            ? null
            : () {
                ref.read(topicProvider.notifier).startTopic(topic);
                Navigator.pop(context);
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.topicTodayLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade300,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.situation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Chip(
                  label: Text(l.topicActive,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final TopicCategory category;
  final List<Topic> topics;
  final String? activeTopicId;

  const _CategorySection({
    required this.category,
    required this.topics,
    this.activeTopicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            _categoryLocalized(AppLocalizations.of(context), category),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...topics.map((topic) {
          final isActive = topic.id == activeTopicId;
          return ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            leading: Icon(
              _categoryIcon(category),
              size: 20,
              color: isActive ? Colors.orange : null,
            ),
            title: Text(
              topic.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.orange : null,
              ),
            ),
            subtitle: Text(
              topic.situation,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isActive
                ? const Icon(Icons.check_circle, color: Colors.orange, size: 18)
                : null,
            onTap: isActive
                ? null
                : () {
                    ref.read(topicProvider.notifier).startTopic(topic);
                    Navigator.pop(context);
                  },
          );
        }),
      ],
    );
  }

  IconData _categoryIcon(TopicCategory cat) {
    return switch (cat) {
      TopicCategory.daily => Icons.wb_sunny,
      TopicCategory.travel => Icons.flight,
      TopicCategory.food => Icons.restaurant,
      TopicCategory.work => Icons.work,
      TopicCategory.shopping => Icons.shopping_bag,
      TopicCategory.health => Icons.local_hospital,
      TopicCategory.social => Icons.people,
      TopicCategory.entertainment => Icons.movie,
    };
  }
}
