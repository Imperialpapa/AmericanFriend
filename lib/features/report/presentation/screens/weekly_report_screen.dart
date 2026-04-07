import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/local_db/app_database.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  List<DailyActivityData> _activities = [];
  List<TopicSession> _topicSessions = [];
  List<LevelHistoryData> _levelHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(appDatabaseProvider);
    final activities = await db.getRecentActivity(7);
    final sessions = await db.getRecentTopicSessions(7);
    final levels = await db.getLevelHistory();

    setState(() {
      _activities = activities;
      _topicSessions = sessions;
      _levelHistory = levels.where((l) {
        return l.assessedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalMessages = _activities.fold<int>(0, (sum, a) => sum + a.messageCount);
    final activeDays = _activities.where((a) => a.goalReached).length;
    final currentStreak = _activities.isNotEmpty ? _activities.first.streakCount : 0;

    // 주제별 턴 수 집계
    final topicTurns = <String, int>{};
    for (final session in _topicSessions) {
      topicTurns[session.topicTitle] =
          (topicTurns[session.topicTitle] ?? 0) + session.turnCount;
    }
    final sortedTopics = topicTurns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 요약 카드
          _SummaryCard(
            totalMessages: totalMessages,
            activeDays: activeDays,
            currentStreak: currentStreak,
          ),

          const SizedBox(height: 16),

          // 일별 활동 차트
          Text('Daily Activity',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _DailyChart(activities: _activities),

          const SizedBox(height: 24),

          // 주제별 연습량
          Text('Topics Practiced',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sortedTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No topic sessions this week.\nTry the Topic Focus mode!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...sortedTopics.map((e) => _TopicRow(
                  title: e.key,
                  turns: e.value,
                  maxTurns: sortedTopics.first.value,
                )),

          const SizedBox(height: 24),

          // 레벨 변화
          Text('Level Changes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_levelHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No level changes this week.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._levelHistory.map((l) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${l.level}', style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text('Level ${l.level}'),
                  subtitle: Text(l.reasoning),
                  trailing: Text(
                    '${l.assessedAt.month}/${l.assessedAt.day}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalMessages;
  final int activeDays;
  final int currentStreak;

  const _SummaryCard({
    required this.totalMessages,
    required this.activeDays,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.chat_bubble,
              value: '$totalMessages',
              label: 'Messages',
              color: Theme.of(context).colorScheme.primary,
            ),
            _StatItem(
              icon: Icons.calendar_today,
              value: '$activeDays/7',
              label: 'Active Days',
              color: Colors.green,
            ),
            _StatItem(
              icon: Icons.local_fire_department,
              value: '$currentStreak',
              label: 'Streak',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _DailyChart extends StatelessWidget {
  final List<DailyActivityData> activities;

  const _DailyChart({required this.activities});

  @override
  Widget build(BuildContext context) {
    // 최근 7일 생성
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    final activityMap = {for (final a in activities) a.date: a};
    final maxCount = activities.isEmpty
        ? 5
        : activities.map((a) => a.messageCount).reduce((a, b) => a > b ? a : b).clamp(5, 100);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((dateStr) {
          final activity = activityMap[dateStr];
          final count = activity?.messageCount ?? 0;
          final goalReached = activity?.goalReached ?? false;
          final barHeight = maxCount > 0 ? (count / maxCount) * 80 : 0.0;
          final dayLabel = dateStr.substring(8); // dd

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 24,
                  height: barHeight.clamp(4.0, 80.0),
                  decoration: BoxDecoration(
                    color: goalReached ? Colors.orange : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String title;
  final int turns;
  final int maxTurns;

  const _TopicRow({
    required this.title,
    required this.turns,
    required this.maxTurns,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: maxTurns > 0 ? turns / maxTurns : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$turns turns',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
