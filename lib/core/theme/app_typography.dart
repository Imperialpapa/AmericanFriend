import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Pretendard-based type scale.
///
/// Source: Claude Design handoff. If the Pretendard font asset is not
/// bundled, Flutter falls back to system sans-serif (still readable).
class KFTypography {
  const KFTypography._();

  static const fontFamily = 'Pretendard';

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required double height,
    required double letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Display (hero headlines)
  static TextStyle display({Color? color}) => _base(
        size: 34,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.68, // -0.02em on 34
        color: color,
      );

  // H1 (page title)
  static TextStyle h1({Color? color}) => _base(
        size: 28,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.56,
        color: color,
      );

  // H2 (section title)
  static TextStyle h2({Color? color}) => _base(
        size: 20,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.30,
        color: color,
      );

  // Body (medium weight — default)
  static TextStyle body({Color? color}) => _base(
        size: 16,
        weight: FontWeight.w500,
        height: 1.45,
        letterSpacing: -0.16,
        color: color,
      );

  // Body regular (paragraph reading)
  static TextStyle bodyR({Color? color}) => _base(
        size: 16,
        weight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.08,
        color: color,
      );

  // Meta (small captions, secondary)
  static TextStyle meta({Color? color}) => _base(
        size: 13,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0,
        color: color,
      );

  // Tiny (uppercase eyebrow labels)
  static TextStyle tiny({Color? color}) => _base(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.22, // 0.02em on 11
        color: color,
      );

  /// Build a Material 3 TextTheme using the KF type scale.
  /// Brightness determines default ink color.
  static TextTheme textTheme(Brightness brightness) {
    final palette = brightness == Brightness.dark ? KFPalette.dark : KFPalette.light;
    return TextTheme(
      displayLarge: display(color: palette.ink),
      displayMedium: display(color: palette.ink),
      displaySmall: h1(color: palette.ink),
      headlineLarge: h1(color: palette.ink),
      headlineMedium: h1(color: palette.ink),
      headlineSmall: h2(color: palette.ink),
      titleLarge: h2(color: palette.ink),
      titleMedium: body(color: palette.ink),
      titleSmall: meta(color: palette.ink),
      bodyLarge: body(color: palette.ink),
      bodyMedium: body(color: palette.ink2),
      bodySmall: meta(color: palette.ink3),
      labelLarge: body(color: palette.ink),
      labelMedium: meta(color: palette.ink2),
      labelSmall: tiny(color: palette.ink3),
    );
  }
}
