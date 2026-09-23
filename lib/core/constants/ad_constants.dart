import 'package:flutter/foundation.dart';

abstract class AdConstants {
  /// Google 공식 테스트 배너 Ad Unit ID
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  /// 프로덕션 배너 Ad Unit ID (AdMob 콘솔에서 발급받은 ID로 교체)
  static const String _prodBannerAdUnitId =
      'ca-app-pub-3130573171479694/2870158802';

  /// 개발 기기에서 release·profile 빌드를 돌릴 때 실광고를 누르면 계정 정지 사유다(tobe P-04).
  ///   flutter build apk --release --dart-define=ADS_FORCE_TEST=true
  static const bool _forceTestAds = bool.fromEnvironment('ADS_FORCE_TEST');

  /// 테스트 기기로 등록할 광고 ID 해시(쉼표 구분). 첫 광고 요청 때 logcat에
  /// "Use RequestConfiguration.Builder().setTestDeviceIds(...)"로 찍히는 값이다.
  ///   --dart-define=ADMOB_TEST_DEVICE_IDS=ABCDEF012345,...
  static const String _testDeviceIdsRaw =
      String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

  static bool get usesTestUnits => kDebugMode || _forceTestAds;

  /// 빌드 모드에 따라 적절한 Ad Unit ID 반환
  static String get bannerAdUnitId =>
      usesTestUnits ? _testBannerAdUnitId : _prodBannerAdUnitId;

  static List<String> get testDeviceIds => parseTestDeviceIds(_testDeviceIdsRaw);

  @visibleForTesting
  static List<String> parseTestDeviceIds(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
