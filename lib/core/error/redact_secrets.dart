/// 오류 문자열에서 API 키로 보이는 부분을 가린다.
///
/// 오류 원문은 '복사' 버튼과 debugPrint(릴리스 logcat에도 찍힌다)로 흘러간다.
/// 제공자 SDK·Dio가 어떤 문자열을 만들지 전부 통제할 수 없으므로, 밖으로
/// 나가는 지점에서 한 번 더 거른다 (tobe S-03).
String redactSecrets(String input) {
  var out = input;
  for (final (pattern, replacement) in _rules) {
    out = out.replaceAllMapped(pattern, replacement);
  }
  return out;
}

// sk-ant-를 sk-보다 먼저 처리해야 접두사가 남는다.
final List<(RegExp, String Function(Match))> _rules = [
  (RegExp(r'AIza[0-9A-Za-z_\-]{8,}'), (_) => 'AIza***'),
  (RegExp(r'sk-ant-[0-9A-Za-z_\-]{8,}'), (_) => 'sk-ant-***'),
  (RegExp(r'sk-[0-9A-Za-z_\-]{8,}'), (_) => 'sk-***'),
  (RegExp(r'gsk_[0-9A-Za-z]{8,}'), (_) => 'gsk_***'),
  (RegExp(r'([?&]key=)[^&\s#]+'), (m) => '${m[1]}***'),
];
