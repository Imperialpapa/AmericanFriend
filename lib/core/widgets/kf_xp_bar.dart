import 'package:flutter/material.dart';
import 'package:eng_friend/core/theme/app_colors.dart';

/// Thin sage progress bar.
class KFXpBar extends StatelessWidget {
  /// 0.0 .. 1.0
  final double value;
  final double? width;
  final double height;

  const KFXpBar({
    super.key,
    required this.value,
    this.width,
    this.height = 3,
  });

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final clamped = value.clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Background track
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: palette.hairline,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
          // Fill
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.sage,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
