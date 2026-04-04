import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';

class LevelIndicator extends ConsumerWidget {
  const LevelIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _levelColor(levelState.currentLevel).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _levelColor(levelState.currentLevel).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv.${levelState.currentLevel}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _levelColor(levelState.currentLevel),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            levelState.levelName,
            style: TextStyle(
              fontSize: 11,
              color: _levelColor(levelState.currentLevel),
            ),
          ),
          if (levelState.isAssessing) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _levelColor(levelState.currentLevel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _levelColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.blue;
    if (level <= 8) return Colors.purple;
    return Colors.orange;
  }
}
