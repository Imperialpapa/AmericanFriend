import 'package:flutter/material.dart';
import 'package:eng_friend/core/widgets/alex_avatar.dart';

/// AI 아바타 위젯 — Modern Sage 리디자인 후 Alex 페블 마스코트.
class AvatarWidget extends StatelessWidget {
  final bool isAnimating;
  final double size;

  const AvatarWidget({
    super.key,
    required this.isAnimating,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return AlexAvatar(
      size: size,
      emotion: isAnimating ? AlexEmotion.listening : AlexEmotion.calm,
    );
  }
}
