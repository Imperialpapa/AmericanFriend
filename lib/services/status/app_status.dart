/// 서버가 내려주는 앱 상태/공지 모델.
///
/// 배경(BUG_HISTORY #9): 외부 제공자가 모델을 셧다운하면 앱이 통째로 사용 불가가 되는데,
/// 앱 배포 없이는 사용자에게 알릴 수도 고칠 수도 없었다. 이 구조가 그 통로다.
library;

import 'package:eng_friend/core/config/proxy_config.dart';

enum NoticeSeverity { info, warning, critical }

/// 공지 링크로 열어도 되는 URL인가(tobe S-08).
/// status는 Vercel 환경변수 하나로 모든 설치본에 퍼진다. 오타나 탈취로 http·javascript:·
/// intent: 링크나 낯선 도메인이 들어와도 열리지 않게 https + 허용 호스트만 통과시킨다.
/// 새 도메인으로 링크를 걸려면 그 호스트를 넣은 앱이 먼저 출시돼야 한다.
bool isAllowedNoticeLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == 'play.google.com' ||
      host == Uri.parse(ProxyConfig.freeTierBaseUrl).host.toLowerCase();
}

class AppNotice {
  final String id;
  final NoticeSeverity severity;

  /// 언어코드 → 문구. 앱 언어에 맞는 걸 골라 쓴다.
  final Map<String, String> title;
  final Map<String, String> body;
  final String? actionUrl;

  const AppNotice({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    this.actionUrl,
  });

  String titleFor(String langCode) => _pick(title, langCode);
  String bodyFor(String langCode) => _pick(body, langCode);

  static String _pick(Map<String, String> m, String langCode) =>
      m[langCode] ?? m['en'] ?? m.values.firstOrNull ?? '';

  static AppNotice? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    return AppNotice(
      id: id,
      severity: switch (raw['severity']) {
        'critical' => NoticeSeverity.critical,
        'warning' => NoticeSeverity.warning,
        _ => NoticeSeverity.info,
      },
      title: _stringMap(raw['title']),
      body: _stringMap(raw['body']),
      actionUrl: switch (raw['actionUrl']) {
        final String url when isAllowedNoticeLink(url) => url.trim(),
        _ => null,
      },
    );
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }
}

class AppStatus {
  /// 이 버전 미만이면 업데이트를 안내한다. null이면 검사 안 함.
  final String? minSupportedVersion;

  final AppNotice? notice;

  /// 죽은 model ID → 살아있는 ID. 앱이 저장된 설정을 스스로 교정하는 데 쓴다.
  /// 제공자가 모델을 내려도 앱 릴리스 없이 복구되는 핵심 장치.
  final Map<String, String> modelMigrations;

  const AppStatus({
    this.minSupportedVersion,
    this.notice,
    this.modelMigrations = const {},
  });

  // 타입이 틀린 필드는 버린다. 던지면 fetch가 이미 저장한 캐시까지 매번 파싱에
  // 실패해서, 서버를 고칠 때까지 공지·마이그레이션이 통째로 멈춘다.
  factory AppStatus.fromJson(Map<String, dynamic> j) => AppStatus(
        minSupportedVersion: switch (j['minSupportedVersion']) {
          final String v => v,
          _ => null,
        },
        notice: AppNotice.fromJson(j['notice']),
        modelMigrations: AppNotice._stringMap(j['modelMigrations']),
      );

  /// [current]가 [minSupportedVersion]보다 낮은가.
  /// "2.5.0" 형태를 숫자 단위로 비교한다. 파싱 실패 시 false(=안내 안 함).
  bool isUpdateRequired(String current) {
    final min = minSupportedVersion;
    if (min == null || min.isEmpty) return false;
    return compareVersions(current, min) < 0;
  }

  /// a < b → 음수, 같으면 0, a > b → 양수
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
