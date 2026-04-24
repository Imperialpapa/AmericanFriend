import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_spacing.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';
import 'package:eng_friend/core/widgets/kf_streak_chip.dart';
import 'package:eng_friend/features/level/presentation/providers/level_provider.dart';
import 'package:eng_friend/features/streak/presentation/providers/streak_provider.dart';
import 'package:eng_friend/features/topic/presentation/providers/topic_provider.dart';
import 'package:eng_friend/features/settings/presentation/screens/settings_screen.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

/// Custom chat header replacing the Material AppBar.
/// Layout: Alex avatar (with status dot) + name/context + StreakChip + Settings gear.
class ChatHeader extends ConsumerWidget implements PreferredSizeWidget {
  const ChatHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    final levelState = ref.watch(levelProvider);
    final streakState = ref.watch(streakProvider);
    final topicState = ref.watch(topicProvider);

    return Material(
      color: palette.paper,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              KFSpacing.x4, KFSpacing.x2, KFSpacing.x3, KFSpacing.x3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.hairline, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Alex avatar with sage status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const AlexAvatar(size: 38, emotion: AlexEmotion.listening),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette.sage,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.paper, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: KFSpacing.x3),

              // Name + context (or topic indicator)
              Expanded(
                child: topicState.isActive
                    ? _topicActiveLabel(context, ref, palette, topicState)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppConstants.aiCharacterName,
                            style: KFTypography.body(color: palette.ink)
                                .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            l.chatHeaderContext(
                              streakState.currentStreak,
                              levelState.currentLevel,
                              levelState.levelName,
                            ),
                            style: KFTypography.tiny(color: palette.ink3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),

              const SizedBox(width: KFSpacing.x2),
              KFStreakChip(days: streakState.currentStreak),
              const SizedBox(width: KFSpacing.x1),
              IconButton(
                icon: Icon(Icons.tune, size: 22, color: palette.ink2),
                tooltip: l.commonSettings,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topicActiveLabel(
      BuildContext context, WidgetRef ref, KFPalette palette, dynamic topicState) {
    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 14, color: palette.mustard),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            topicState.activeTopic!.title,
            style: KFTypography.body(color: palette.sageDeep).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => ref.read(topicProvider.notifier).endTopic(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.close, size: 16, color: palette.ink3),
          ),
        ),
      ],
    );
  }
}
