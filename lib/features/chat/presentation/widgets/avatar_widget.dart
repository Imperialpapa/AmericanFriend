import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// AI 아바타 위젯 - dotLottie 애니메이션 표시
class AvatarWidget extends StatefulWidget {
  final bool isAnimating;

  const AvatarWidget({super.key, required this.isAnimating});

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: DotLottieLoader.fromAsset(
        'assets/lottie/talking girl.lottie',
        frameBuilder: (ctx, dotlottie) {
          if (dotlottie != null) {
            return Lottie.memory(
              dotlottie.animations.values.single,
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                if (widget.isAnimating) {
                  _controller.repeat();
                }
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
