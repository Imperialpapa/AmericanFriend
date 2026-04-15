import 'package:flutter/foundation.dart';

abstract class AdConstants {
  /// Google 공식 테스트 배너 Ad Unit ID
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  /// 프로덕션 배너 Ad Unit ID (AdMob 콘솔에서 발급받은 ID로 교체)
  static const String _prodBannerAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  /// 빌드 모드에 따라 적절한 Ad Unit ID 반환
  static String get bannerAdUnitId =>
      kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
}
