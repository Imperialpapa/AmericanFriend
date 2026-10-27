import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/services/status/app_status.dart';

void main() {
  group('compareVersions', () {
    test('숫자 단위로 비교한다 (문자열 비교 아님)', () {
      expect(AppStatus.compareVersions('2.5.0', '2.5.1'), lessThan(0));
      expect(AppStatus.compareVersions('2.10.0', '2.9.9'), greaterThan(0));
      expect(AppStatus.compareVersions('2.5.1', '2.5.1'), 0);
    });

    test('빌드 번호(+N)는 무시하고, 빠진 자리는 0으로 본다', () {
      expect(AppStatus.compareVersions('2.5.1+26', '2.5.1'), 0);
      expect(AppStatus.compareVersions('2.5', '2.5.0'), 0);
    });
  });

  group('isUpdateRequired', () {
    test('최소 버전이 없거나 비면 안내하지 않는다', () {
      expect(const AppStatus().isUpdateRequired('1.0.0'), isFalse);
      expect(
          const AppStatus(minSupportedVersion: '').isUpdateRequired('1.0.0'),
          isFalse);
    });

    test('현재 버전이 최소 버전보다 낮을 때만 안내한다', () {
      const status = AppStatus(minSupportedVersion: '2.5.1');
      expect(status.isUpdateRequired('2.5.0'), isTrue);
      expect(status.isUpdateRequired('2.5.1'), isFalse);
      expect(status.isUpdateRequired('2.6.0'), isFalse);
    });
  });

  group('isAllowedNoticeLink', () {
    test('https + 허용 호스트만 통과', () {
      expect(
          isAllowedNoticeLink(
              'https://play.google.com/store/apps/details?id=com.engfriend.eng_friend'),
          isTrue);
      expect(isAllowedNoticeLink('https://american-friend.vercel.app/notice'),
          isTrue);
      expect(isAllowedNoticeLink('https://PLAY.GOOGLE.COM/store'), isTrue);
    });

    test('스킴이 https가 아니면 막는다', () {
      for (final url in const [
        'http://play.google.com/store',
        'javascript:alert(1)',
        'intent://scan#Intent;scheme=zxing;end',
        'market://details?id=com.engfriend.eng_friend',
        'file:///sdcard/x',
      ]) {
        expect(isAllowedNoticeLink(url), isFalse, reason: url);
      }
    });

    test('허용 목록에 없는 호스트와 userinfo 위장을 막는다', () {
      for (final url in const [
        'https://evil.example.com/play.google.com',
        'https://play.google.com.evil.example.com/',
        'https://play.google.com@evil.example.com/',
        'not a url',
        '',
      ]) {
        expect(isAllowedNoticeLink(url), isFalse, reason: url);
      }
    });
  });

  group('fromJson', () {
    test('허용되지 않은 actionUrl은 버리고 공지는 살린다', () {
      final notice = AppNotice.fromJson({
        'id': 'n1',
        'severity': 'warning',
        'title': {'ko': '점검', 'en': 'Maintenance'},
        'body': {'en': 'Soon'},
        'actionUrl': 'http://example.com',
      });
      expect(notice, isNotNull);
      expect(notice!.actionUrl, isNull);
      expect(notice.severity, NoticeSeverity.warning);
      expect(notice.titleFor('ko'), '점검');
      expect(notice.bodyFor('ko'), 'Soon'); // ko가 없으면 en
    });

    test('id가 없으면 공지 없음', () {
      expect(AppNotice.fromJson({'severity': 'critical'}), isNull);
      expect(AppNotice.fromJson('not a map'), isNull);
    });

    test('타입이 틀린 필드는 던지지 않고 버린다', () {
      final status = AppStatus.fromJson({
        'minSupportedVersion': 251,
        'notice': 'oops',
        'modelMigrations': {'a': 'b', 'c': 3},
        'flags': 'oops',
      });
      expect(status.minSupportedVersion, isNull);
      expect(status.notice, isNull);
      expect(status.modelMigrations, {'a': 'b'});
      expect(status.flags, isEmpty);
    });
  });

  group('원격 스위치(flags)', () {
    test('불리언 값만 받는다 — 문자열 "false"는 버려 앱 기본값을 쓴다', () {
      final status = AppStatus.fromJson({
        'flags': {
          RemoteFlags.handsFree: false,
          'typo_flag': 'false',
          'count': 0,
        },
      });
      expect(status.flags, {RemoteFlags.handsFree: false});
    });

    test('서버에 없는 키는 fallback', () {
      const status = AppStatus(flags: {RemoteFlags.handsFree: false});
      expect(status.isEnabled(RemoteFlags.handsFree, fallback: true), isFalse);
      expect(status.isEnabled('other', fallback: true), isTrue);
      expect(const AppStatus().isEnabled(RemoteFlags.handsFree, fallback: true),
          isTrue);
    });
  });
}
