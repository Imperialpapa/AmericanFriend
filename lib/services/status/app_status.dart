/// 서버가 내려주는 앱 상태/공지 모델.
///
/// 배경(BUG_HISTORY #9): 외부 제공자가 모델을 셧다운하면 앱이 통째로 사용 불가가 되는데,
/// 앱 배포 없이는 사용자에게 알릴 수도 고칠 수도 없었다. 이 구조가 그 통로다.
library;

enum NoticeSeverity { info, warning, critical }

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
      actionUrl: raw['actionUrl'] is String ? raw['actionUrl'] as String : null,
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

  factory AppStatus.fromJson(Map<String, dynamic> j) => AppStatus(
        minSupportedVersion: j['minSupportedVersion'] as String?,
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
