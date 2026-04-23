import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eng_friend/core/theme/app_colors.dart';

/// Alex — abstract pebble mascot.
///
/// Body is an asymmetric blob (per-corner elliptical radii), with a sage
/// gradient, soft highlight, optional mustard cheek blush, and per-emotion
/// decorations. No mouth, no gender cues.
enum AlexEmotion { calm, thinking, celebrate, listening }

class AlexAvatar extends StatelessWidget {
  final double size;
  final AlexEmotion emotion;

  const AlexAvatar({
    super.key,
    this.size = 64,
    this.emotion = AlexEmotion.calm,
  });

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    final mood = _moodFor(emotion);
    final eyeWidth = math.max(3.0, size * 0.09);
    final eyeGap = size * mood.eyeGap;
    final blushSize = size * 0.12;

    return Transform.rotate(
      angle: mood.tilt * math.pi / 180,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Drop shadow (below the body) — simple BoxShadow instead of blur filter
            Positioned(
              left: size * 0.12,
              right: size * 0.12,
              bottom: -size * 0.02,
              height: size * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: palette.sageDeep.withValues(alpha: 0.18),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Body — asymmetric blob with sage gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _bodyRadius(mood, size),
                  gradient: LinearGradient(
                    begin: const Alignment(-0.2, -1),
                    end: const Alignment(0.6, 1),
                    colors: [palette.sage, palette.sageDeep],
                  ),
                ),
              ),
            ),

            // Soft top-left highlight — plain ellipse with alpha
            Positioned(
              top: size * 0.14,
              left: size * 0.18,
              width: size * 0.28,
              height: size * 0.22,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0x59FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Eyes
            Positioned(
              top: size * 0.46 - mood.eyeHeight / 2,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _eye(eyeWidth, mood.eyeHeight),
                    SizedBox(width: eyeGap),
                    _eye(eyeWidth, mood.eyeHeight),
                  ],
                ),
              ),
            ),

            // Mustard cheek blush
            if (mood.blush > 0) ...[
              Positioned(
                top: size * 0.58,
                left: size * 0.14,
                child: _blush(blushSize, mood.blush, palette.mustard),
              ),
              Positioned(
                top: size * 0.58,
                right: size * 0.14,
                child: _blush(blushSize, mood.blush, palette.mustard),
              ),
            ],

            // Celebrate sparkle (top-right)
            if (emotion == AlexEmotion.celebrate)
              Positioned(
                top: -size * 0.12,
                right: -size * 0.08,
                width: size * 0.22,
                height: size * 0.22,
                child: CustomPaint(
                  painter: _SparklePainter(palette.mustard),
                ),
              ),

            // Thinking dots (top-right)
            if (emotion == AlexEmotion.thinking)
              Positioned(
                top: -size * 0.14,
                right: -size * 0.18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _thinkingDot(size * 0.06, 0.5, palette.sage),
                    const SizedBox(width: 3),
                    _thinkingDot(size * 0.06, 0.7, palette.sage),
                    const SizedBox(width: 3),
                    _thinkingDot(size * 0.06, 1.0, palette.sage),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eye(double w, double h) {
    final isThinking = emotion == AlexEmotion.thinking;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(isThinking ? 2 : 999),
      ),
    );
  }

  Widget _blush(double size, double opacity, Color color) {
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity * 0.45),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _thinkingDot(double size, double opacity, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Per-corner elliptical radii to produce an asymmetric blob.
  /// Mirrors the CSS `border-radius: a% b% c% d% / e% f% g% h%` syntax.
  BorderRadius _bodyRadius(_Mood m, double s) {
    final r = m.bodyRadius;
    return BorderRadius.only(
      topLeft: Radius.elliptical(s * r.tlX, s * r.tlY),
      topRight: Radius.elliptical(s * r.trX, s * r.trY),
      bottomRight: Radius.elliptical(s * r.brX, s * r.brY),
      bottomLeft: Radius.elliptical(s * r.blX, s * r.blY),
    );
  }

  _Mood _moodFor(AlexEmotion e) {
    switch (e) {
      case AlexEmotion.calm:
        return const _Mood(
          bodyRadius: _BodyRadius(0.58, 0.50, 0.42, 0.55, 0.55, 0.45, 0.45, 0.50),
          eyeHeight: 6,
          eyeGap: 0.42,
          blush: 0.9,
          tilt: 0,
        );
      case AlexEmotion.thinking:
        return const _Mood(
          bodyRadius: _BodyRadius(0.55, 0.45, 0.45, 0.60, 0.60, 0.40, 0.40, 0.55),
          eyeHeight: 3,
          eyeGap: 0.36,
          blush: 0.4,
          tilt: -6,
        );
      case AlexEmotion.celebrate:
        return const _Mood(
          bodyRadius: _BodyRadius(0.60, 0.60, 0.40, 0.40, 0.50, 0.60, 0.50, 0.40),
          eyeHeight: 8,
          eyeGap: 0.44,
          blush: 1.0,
          tilt: 4,
        );
      case AlexEmotion.listening:
        return const _Mood(
          bodyRadius: _BodyRadius(0.55, 0.55, 0.45, 0.45, 0.50, 0.50, 0.50, 0.50),
          eyeHeight: 7,
          eyeGap: 0.42,
          blush: 0.7,
          tilt: 0,
        );
    }
  }
}

class _Mood {
  final _BodyRadius bodyRadius;
  final double eyeHeight;
  final double eyeGap;
  final double blush;
  final double tilt;

  const _Mood({
    required this.bodyRadius,
    required this.eyeHeight,
    required this.eyeGap,
    required this.blush,
    required this.tilt,
  });
}

class _BodyRadius {
  final double tlX, tlY, trX, trY, brX, brY, blX, blY;
  const _BodyRadius(
      this.tlX, this.tlY, this.trX, this.trY, this.brX, this.brY, this.blX, this.blY);
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.6, h * 0.4)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.6, h * 0.6)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.4, h * 0.6)
      ..lineTo(0, h * 0.5)
      ..lineTo(w * 0.4, h * 0.4)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}
