import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/kf_xp_bar.dart';
import 'package:eng_friend/features/mission/presentation/providers/mission_provider.dart';
import 'package:eng_friend/features/mission/presentation/widgets/mission_bottom_sheet.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';

/// Sage-wash card showing today's progress (or active mission progress).
/// Tappable → opens mission bottom sheet.
class MissionStrip extends ConsumerWidget {
  const MissionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final missionState = ref.watch(missionProvider);
    final streakState = ref.watch(streakProvider);

    final bool missionActive = missionState.isActive;
    final String label;
    final String trailing;
    final double progress;

    if (missionActive) {
      final mission = missionState.activeMission!;
      label = 'Mission · ${missionState.turnCount} of ${mission.requiredTurns}';
      trailing = '+${mission.difficulty.stars}★';
      progress = (missionState.turnCount / mission.requiredTurns).clamp(0.0, 1.0);
    } else {
      final today = streakState.todayMessageCount;
      final goal = streakState.dailyGoal;
      label = streakState.goalReachedToday
          ? 'Goal reached · $today of $goal'
          : "Today's goal · $today of $goal";
      trailing = streakState.goalReachedToday
          ? '✓ Done'
          : '+${goal - today} to go';
      progress = goal > 0 ? (today / goal).clamp(0.0, 1.0) : 0.0;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          KFSpacing.x4, KFSpacing.x3, KFSpacing.x4, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: KFRadii.rMd,
          onTap: () => MissionBottomSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KFSpacing.x3, vertical: 10),
            decoration: BoxDecoration(
              color: palette.sageWash,
              borderRadius: KFRadii.rMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.sage,
                    borderRadius: BorderRadius.circular(KFRadii.xs + 2),
                  ),
                  child: Icon(
                    missionActive ? Icons.adjust : Icons.local_fire_department,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: KFSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: KFTypography.meta(color: palette.ink).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      KFXpBar(value: progress),
                    ],
                  ),
                ),
                const SizedBox(width: KFSpacing.x3),
                Text(
                  trailing,
                  style: KFTypography.tiny(color: palette.sageDeep).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
