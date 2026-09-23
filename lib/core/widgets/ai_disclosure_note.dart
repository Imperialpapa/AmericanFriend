import 'package:flutter/material.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/l10n/app_localizations.dart';

/// "AI가 만든 답변이라 틀릴 수 있어요" 한 줄 고지(tobe P-03).
/// 무료 티어 경로는 BYOK 안내 페이지를 건너뛰므로 첫 화면들에서 직접 알린다.
class AiDisclosureNote extends StatelessWidget {
  const AiDisclosureNote({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = KFPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 14, color: palette.ink3),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            AppLocalizations.of(context).aiMayBeWrongNote,
            textAlign: TextAlign.center,
            style: KFTypography.meta(color: palette.ink3),
          ),
        ),
      ],
    );
  }
}
