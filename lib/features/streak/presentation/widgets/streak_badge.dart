import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';

/// AppBar 옆에 표시되는 streak 배지
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: streak.goalReachedToday
            ? Colors.orange.withOpacity(0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: streak.goalReachedToday
                ? Colors.orange
                : Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            '${streak.currentStreak}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: streak.goalReachedToday
                  ? Colors.orange
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          // 오늘 진행률 (미니 프로그레스)
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: streak.goalReachedToday
                      ? 1.0
                      : streak.todayMessageCount / streak.dailyGoal,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    streak.goalReachedToday
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${streak.todayMessageCount}',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
