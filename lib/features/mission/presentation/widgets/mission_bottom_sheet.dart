import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/features/mission/domain/entities/mission.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

String _difficultyLocalized(AppLocalizations l, MissionDifficulty d) => switch (d) {
      MissionDifficulty.easy => l.missionDifficultyEasy,
      MissionDifficulty.medium => l.missionDifficultyMedium,
      MissionDifficulty.hard => l.missionDifficultyHard,
    };

class MissionBottomSheet extends ConsumerWidget {
  const MissionBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const MissionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(missionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, size: 24, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).missionSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${missionState.completedMissionIds.length}/${MissionCatalog.all.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ..._buildDifficultySection(context, ref, MissionDifficulty.easy, missionState),
                  ..._buildDifficultySection(context, ref, MissionDifficulty.medium, missionState),
                  ..._buildDifficultySection(context, ref, MissionDifficulty.hard, missionState),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDifficultySection(
    BuildContext context,
    WidgetRef ref,
    MissionDifficulty difficulty,
    MissionState missionState,
  ) {
    final missions = MissionCatalog.all.where((m) => m.difficulty == difficulty).toList();
    final starColor = switch (difficulty) {
      MissionDifficulty.easy => Colors.green,
      MissionDifficulty.medium => Colors.orange,
      MissionDifficulty.hard => Colors.red,
    };

    final l = AppLocalizations.of(context);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            ...List.generate(difficulty.stars, (_) => Icon(Icons.star, size: 16, color: starColor)),
            const SizedBox(width: 6),
            Text(
              _difficultyLocalized(l, difficulty),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: starColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
      ...missions.map((mission) {
        final isCompleted = missionState.completedMissionIds.contains(mission.id);
        final isActive = missionState.activeMission?.id == mission.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.radio_button_unchecked, color: Colors.grey[600]),
            title: Text(
              mission.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.description),
                const SizedBox(height: 4),
                Text(
                  l.missionTurnsNeeded(mission.requiredTurns),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: isActive
                ? Chip(
                    label: Text('${missionState.turnCount}/${mission.requiredTurns}'),
                    backgroundColor: starColor,
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11),
                  )
                : null,
            onTap: isActive
                ? null
                : () {
                    ref.read(missionProvider.notifier).startMission(mission);
                    Navigator.pop(context);
                  },
          ),
        );
      }),
    ];
  }
}
