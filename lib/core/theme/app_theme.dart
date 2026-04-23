import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Builds Material 3 ThemeData wired to the Modern Sage palette.
class KFTheme {
  const KFTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final palette = brightness == Brightness.dark ? KFPalette.dark : KFPalette.light;
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.sage,
      onPrimary: isDark ? palette.ink : Colors.white,
      primaryContainer: palette.sageWash,
      onPrimaryContainer: palette.sageDeep,
      secondary: palette.mustard,
      onSecondary: isDark ? palette.ink : palette.ink,
      secondaryContainer: palette.mustardSoft,
      onSecondaryContainer: isDark ? palette.mustard : const Color(0xFF614A1C),
      tertiary: palette.indigo,
      onTertiary: Colors.white,
      tertiaryContainer: palette.beige,
      onTertiaryContainer: palette.ink,
      error: palette.coral,
      onError: isDark ? palette.ink : Colors.white,
      errorContainer: isDark ? const Color(0xFF4D2A1F) : const Color(0xFFFADBCB),
      onErrorContainer: isDark ? palette.coral : const Color(0xFF7A2E13),
      surface: palette.paper,
      onSurface: palette.ink,
      surfaceContainerLowest: palette.canvas,
      surfaceContainerLow: palette.paper,
      surfaceContainer: palette.card,
      surfaceContainerHigh: palette.beige,
      surfaceContainerHighest: palette.beigeIn,
      onSurfaceVariant: palette.ink2,
      outline: palette.hairline,
      outlineVariant: palette.hairline,
      shadow: Colors.black.withValues(alpha: 0.08),
      scrim: Colors.black54,
      inverseSurface: isDark ? palette.paper : palette.ink,
      onInverseSurface: isDark ? palette.ink : palette.paper,
      inversePrimary: isDark ? KFColors.lightSage : KFColors.darkSage,
    );

    final textTheme = KFTypography.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.canvas,
      textTheme: textTheme,
      fontFamily: KFTypography.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: KFTypography.h2(color: palette.ink),
        iconTheme: IconThemeData(color: palette.ink2),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: KFRadii.rXl,
          side: BorderSide(color: palette.hairline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.sage,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: KFRadii.rMd),
          textStyle: KFTypography.body().copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.hairline),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: KFRadii.rSm),
          textStyle: KFTypography.body(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.ink2,
          textStyle: KFTypography.body(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: palette.ink2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.beige,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: KFRadii.rMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: KFRadii.rMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KFRadii.rMd,
          borderSide: BorderSide(color: palette.sage, width: 1.5),
        ),
        hintStyle: KFTypography.body(color: palette.ink3),
        labelStyle: KFTypography.meta(color: palette.ink2),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 0.5,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? palette.ink3 : palette.ink2;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.sage;
          return palette.hairline;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.sage,
        inactiveTrackColor: palette.hairline,
        thumbColor: palette.sage,
        overlayColor: palette.sage.withValues(alpha: 0.12),
        valueIndicatorColor: palette.sageDeep,
        valueIndicatorTextStyle: KFTypography.meta(color: Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.sage,
        linearTrackColor: palette.hairline,
        circularTrackColor: palette.hairline,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: KFTypography.body(color: palette.paper),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: KFRadii.rMd),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(KFRadii.xxl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: KFRadii.rXl),
        titleTextStyle: KFTypography.h2(color: palette.ink),
        contentTextStyle: KFTypography.body(color: palette.ink2),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.sage,
        unselectedLabelColor: palette.ink3,
        indicatorColor: palette.sage,
        labelStyle: KFTypography.body().copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: KFTypography.body(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: palette.beige,
          foregroundColor: palette.ink2,
          selectedBackgroundColor: palette.sage,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: palette.hairline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.ink2,
        textColor: palette.ink,
        titleTextStyle: KFTypography.body(color: palette.ink),
        subtitleTextStyle: KFTypography.meta(color: palette.ink3),
      ),
    );
  }
}
