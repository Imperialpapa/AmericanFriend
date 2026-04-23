import 'package:flutter/material.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_radii.dart';
import 'package:eng_friend/core/theme/app_typography.dart';

/// Mustard pill with flame + day count.
class KFStreakChip extends StatelessWidget {
  final int days;

  const KFStreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flameColor = isDark
        ? palette.mustard
        : const Color(0xFFB87324); // darker mustard for legibility
    final textColor = isDark
        ? palette.mustard
        : const Color(0xFF614A1C);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: palette.mustardSoft,
        borderRadius: KFRadii.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 13, color: flameColor),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: KFTypography.meta(color: textColor).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
