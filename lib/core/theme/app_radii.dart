import 'package:flutter/widgets.dart';

/// Border radius tokens. Standardizes the 4/8/12/14/16/18/20/24 chaos
/// in the original codebase to a 6-step scale + full-pill.
class KFRadii {
  const KFRadii._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rFull = BorderRadius.all(Radius.circular(full));

  /// AI message bubble (left): top corners + bottom-right rounded, bottom-left sharp.
  static const BorderRadius aiBubble = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
    bottomLeft: Radius.circular(xs),
    bottomRight: Radius.circular(lg),
  );

  /// User message bubble (right): top corners + bottom-left rounded, bottom-right sharp.
  static const BorderRadius userBubble = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(xs),
  );
}
