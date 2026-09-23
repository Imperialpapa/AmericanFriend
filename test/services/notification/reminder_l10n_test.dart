import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/app.dart';
import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/l10n/app_localizations.dart';
import 'package:eng_friend/services/language/app_language.dart';

void main() {
  group('리마인더 문구 로케일 (X-16)', () {
    // 리마인더는 context 밖에서 lookupAppLocalizations로 문구를 만든다.
    // arb가 없는 로케일이 나오면 FlutterError로 재예약이 통째로 실패한다.
    test('모든 모국어가 arb가 있는 UI 로케일로 매핑된다', () {
      for (final lang in AppLanguage.values) {
        final l = lookupAppLocalizations(resolveUiLocale(lang));
        expect(l.reminderNotificationTitle, isNotEmpty, reason: lang.code);
        expect(l.reminderChannelName, isNotEmpty, reason: lang.code);
        expect(l.reminderChannelDescription, isNotEmpty, reason: lang.code);
        expect(
          l.reminderNotificationBody(AppConstants.aiCharacterName),
          contains(AppConstants.aiCharacterName),
          reason: lang.code,
        );
      }
    });

    test('한국어 모국어는 한국어 문구, 나머지는 영어 문구', () {
      expect(resolveUiLocale(AppLanguage.korean), const Locale('ko'));
      expect(resolveUiLocale(AppLanguage.englishUS), const Locale('en'));

      final ko = lookupAppLocalizations(resolveUiLocale(AppLanguage.korean));
      final en = lookupAppLocalizations(resolveUiLocale(AppLanguage.englishUS));
      expect(ko.reminderNotificationTitle, isNot(en.reminderNotificationTitle));
    });
  });
}
