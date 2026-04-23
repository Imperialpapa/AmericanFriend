import 'package:flutter/widgets.dart';

/// Soft elevation tokens. Used sparingly — light mode only;
/// dark mode prefers borders over shadows.
class KFShadows {
  const KFShadows._();

  /// Card / message bubble — barely-there.
  static const List<BoxShadow> card = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x0A1E3228), // ~rgba(30,50,40,0.04)
    ),
  ];

  /// Sage CTA button — soft sage glow.
  static const List<BoxShadow> sageCta = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 14,
      color: Color(0x4D6FA388), // sage @ ~30% alpha
    ),
  ];

  /// Mic button — pronounced sage shadow.
  static const List<BoxShadow> sageMic = [
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 6,
      color: Color(0x4D6FA388),
    ),
  ];

  /// User message bubble — subtle dark green tint.
  static const List<BoxShadow> userBubble = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x1F1E3C32), // rgba(30,60,50,0.12)
    ),
  ];
}
