import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';
import 'package:eng_friend/core/theme/app_typography.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/status/app_status.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.engfriend.eng_friend';

/// 서버가 내려준 공지 / 업데이트 안내를 화면 상단에 띄운다.
///
/// 존재 이유(BUG_HISTORY #9): 외부 제공자가 모델을 셧다운하면 앱이 통째로 사용 불가가
/// 되는데, 사용자는 이유를 알 방법이 없고 개발자는 앱 배포 없이 알릴 방법이 없었다.
/// 공지 문구는 Vercel 환경변수 `STATUS_NOTICE_JSON` 하나로 즉시 바뀐다.
class AppNoticeBanner extends ConsumerStatefulWidget {
  const AppNoticeBanner({super.key});

  @override
  ConsumerState<AppNoticeBanner> createState() => _AppNoticeBannerState();
}

class _AppNoticeBannerState extends ConsumerState<AppNoticeBanner> {
  bool _dismissedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appStatusProvider).value;
    if (status == null) return const SizedBox.shrink();

    final palette = KFPalette.of(context);
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    // 업데이트 안내가 공지보다 우선. 앱이 아예 못 쓰는 상태일 수 있으므로 닫을 수 없다.
    if (status.isUpdateRequired(AppConstants.appVersion)) {
      return _Bar(
        palette: palette,
        background: palette.coral.withValues(alpha: 0.14),
        icon: Icons.system_update,
        iconColor: palette.coral,
        title: l.noticeUpdateTitle,
        body: l.noticeUpdateBody,
        actionLabel: l.noticeUpdateAction,
        onAction: () => _open(status.notice?.actionUrl ?? _playStoreUrl),
        onDismiss: null,
      );
    }

    final notice = status.notice;
    if (notice == null) return const SizedBox.shrink();
    if (_dismissedThisSession) return const SizedBox.shrink();

    final service = ref.read(appStatusServiceProvider);
    // critical은 사용자가 닫아도 다음 실행에 다시 보여준다.
    final dismissible = notice.severity != NoticeSeverity.critical;
    if (dismissible && service.isNoticeDismissed(notice.id)) {
      return const SizedBox.shrink();
    }

    final (bg, iconColor, icon) = switch (notice.severity) {
      NoticeSeverity.critical => (
          palette.coral.withValues(alpha: 0.14),
          palette.coral,
          Icons.error_outline,
        ),
      NoticeSeverity.warning => (
          palette.mustard.withValues(alpha: 0.16),
          palette.mustard,
          Icons.warning_amber_rounded,
        ),
      NoticeSeverity.info => (
          palette.sageWash,
          palette.sageDeep,
          Icons.info_outline,
        ),
    };

    return _Bar(
      palette: palette,
      background: bg,
      icon: icon,
      iconColor: iconColor,
      title: notice.titleFor(lang),
      body: notice.bodyFor(lang),
      actionLabel: notice.actionUrl != null ? l.noticeDetails : null,
      onAction:
          notice.actionUrl != null ? () => _open(notice.actionUrl!) : null,
      onDismiss: dismissible
          ? () async {
              await service.dismissNotice(notice.id);
              if (mounted) setState(() => _dismissedThisSession = true);
            }
          : null,
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Bar extends StatelessWidget {
  final KFPalette palette;
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const _Bar({
    required this.palette,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: KFTypography.meta(color: palette.ink)
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: KFTypography.meta(color: palette.ink2)
                        .copyWith(fontSize: 12, height: 1.4),
                  ),
                ],
                if (actionLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: onAction,
                      child: Text(
                        actionLabel!,
                        style: KFTypography.meta(color: iconColor).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: palette.ink3),
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}
