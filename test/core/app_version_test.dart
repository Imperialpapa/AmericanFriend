import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/core/constants/app_constants.dart';

/// 업데이트 배너·UA·설정 화면·신고가 AppConstants.appVersion을 쓴다. pubspec만 올리고
/// 상수를 빠뜨리면 Play 2.5.0처럼 설정에 옛 버전이 찍히고, minSupportedVersion을
/// 올렸을 때 최신 앱에도 닫을 수 없는 업데이트 배너가 뜬다(tobe R-07).
void main() {
  test('AppConstants.appVersion이 pubspec.yaml version과 같다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml에 version이 없다');
    expect(AppConstants.appVersion, match!.group(1));
  });
}
