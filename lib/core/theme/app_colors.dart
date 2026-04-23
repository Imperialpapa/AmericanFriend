import 'package:flutter/material.dart';

/// Modern Sage palette — Korean Friend redesign
///
/// Source: Claude Design handoff (2026-04-23). Original colors defined in
/// oklch; converted here to sRGB hex (approximate). Hue/chroma intent:
/// sage primary, warm beige surfaces, mustard accent, coral for streak,
/// indigo for info/links.
class KFColors {
  const KFColors._();

  // ===== LIGHT =====
  static const lightPaper = Color(0xFFFBFAF6);
  static const lightCanvas = Color(0xFFF4F1EB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBeige = Color(0xFFEFE9DC);
  static const lightBeigeIn = Color(0xFFE5DCC9);

  static const lightInk = Color(0xFF2A322B);
  static const lightInk2 = Color(0xFF5C6964);
  static const lightInk3 = Color(0xFF8C9690);
  static const lightHairline = Color(0xFFE2E1D9);

  static const lightSage = Color(0xFF6FA388);
  static const lightSageDeep = Color(0xFF4A7560);
  static const lightSageSoft = Color(0xFFC8DACF);
  static const lightSageWash = Color(0xFFECF1ED);

  static const lightMustard = Color(0xFFD4A24A);
  static const lightMustardSoft = Color(0xFFECDCAB);
  static const lightCoral = Color(0xFFE89776);
  static const lightIndigo = Color(0xFF5870C7);

  // ===== DARK =====
  static const darkPaper = Color(0xFF1F2422);
  static const darkCanvas = Color(0xFF181C1A);
  static const darkCard = Color(0xFF272D2A);
  static const darkBeige = Color(0xFF3A3528);
  static const darkBeigeIn = Color(0xFF443D2C);

  static const darkInk = Color(0xFFF5F3ED);
  static const darkInk2 = Color(0xFFB6BEB1);
  static const darkInk3 = Color(0xFF818A82);
  static const darkHairline = Color(0xFF424A45);

  static const darkSage = Color(0xFF88B89E);
  static const darkSageDeep = Color(0xFF6A9B82);
  static const darkSageSoft = Color(0xFF485955);
  static const darkSageWash = Color(0xFF2C3933);

  static const darkMustard = Color(0xFFDDB05A);
  static const darkMustardSoft = Color(0xFF4D4329);
  static const darkCoral = Color(0xFFEB9D78);
  static const darkIndigo = Color(0xFF91A2DC);
}

/// Theme-aware accessor — read tokens via `KFPalette.of(context)`.
class KFPalette {
  final Color paper;
  final Color canvas;
  final Color card;
  final Color beige;
  final Color beigeIn;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color hairline;
  final Color sage;
  final Color sageDeep;
  final Color sageSoft;
  final Color sageWash;
  final Color mustard;
  final Color mustardSoft;
  final Color coral;
  final Color indigo;

  const KFPalette({
    required this.paper,
    required this.canvas,
    required this.card,
    required this.beige,
    required this.beigeIn,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.hairline,
    required this.sage,
    required this.sageDeep,
    required this.sageSoft,
    required this.sageWash,
    required this.mustard,
    required this.mustardSoft,
    required this.coral,
    required this.indigo,
  });

  static const light = KFPalette(
    paper: KFColors.lightPaper,
    canvas: KFColors.lightCanvas,
    card: KFColors.lightCard,
    beige: KFColors.lightBeige,
    beigeIn: KFColors.lightBeigeIn,
    ink: KFColors.lightInk,
    ink2: KFColors.lightInk2,
    ink3: KFColors.lightInk3,
    hairline: KFColors.lightHairline,
    sage: KFColors.lightSage,
    sageDeep: KFColors.lightSageDeep,
    sageSoft: KFColors.lightSageSoft,
    sageWash: KFColors.lightSageWash,
    mustard: KFColors.lightMustard,
    mustardSoft: KFColors.lightMustardSoft,
    coral: KFColors.lightCoral,
    indigo: KFColors.lightIndigo,
  );

  static const dark = KFPalette(
    paper: KFColors.darkPaper,
    canvas: KFColors.darkCanvas,
    card: KFColors.darkCard,
    beige: KFColors.darkBeige,
    beigeIn: KFColors.darkBeigeIn,
    ink: KFColors.darkInk,
    ink2: KFColors.darkInk2,
    ink3: KFColors.darkInk3,
    hairline: KFColors.darkHairline,
    sage: KFColors.darkSage,
    sageDeep: KFColors.darkSageDeep,
    sageSoft: KFColors.darkSageSoft,
    sageWash: KFColors.darkSageWash,
    mustard: KFColors.darkMustard,
    mustardSoft: KFColors.darkMustardSoft,
    coral: KFColors.darkCoral,
    indigo: KFColors.darkIndigo,
  );

  static KFPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
