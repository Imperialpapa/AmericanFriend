import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/core/constants/ad_constants.dart';

void main() {
  test('ADMOB_TEST_DEVICE_IDS: 쉼표로 나누고 공백·빈 항목은 버린다', () {
    expect(AdConstants.parseTestDeviceIds(''), isEmpty);
    expect(AdConstants.parseTestDeviceIds('ABC123'), ['ABC123']);
    expect(AdConstants.parseTestDeviceIds(' ABC123 , ,DEF456,'),
        ['ABC123', 'DEF456']);
  });

  test('flutter test는 debug 모드라 테스트 광고 단위를 쓴다', () {
    expect(AdConstants.usesTestUnits, isTrue);
    expect(AdConstants.bannerAdUnitId, startsWith('ca-app-pub-3940256099942544/'));
  });
}
