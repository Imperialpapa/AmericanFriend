abstract class AppConstants {
  static const String appName = 'Korean Friend';
  static const String aiCharacterName = 'Alex';
  /// pubspec.yaml의 version과 수동 동기화 필요.
  static const String appVersion = '2.5.0';

  /// 처리방침 공개 URL(Play Console에 등록하는 주소와 같게). 비어 있으면 앱 안의
  /// 번들 텍스트만 보여 주고, 채우면 처리방침 화면에 '브라우저에서 열기'가 생긴다.
  static const String privacyPolicyUrl = '';

  static const int defaultSuggestionDelaySec = 5;
  static const int maxSuggestionCount = 3;
}
