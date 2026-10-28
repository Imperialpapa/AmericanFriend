import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eng_friend/di/service_providers.dart';
import 'package:eng_friend/services/status/app_status.dart';

/// 핸즈프리 원격 스위치(tobe Q-05). 서버에 닿지 못해도 핸즈프리가 막히면 안 되고,
/// 서버가 끄면 꺼져야 한다.
void main() {
  Future<bool> allowedWith(AppStatus? status) async {
    final container = ProviderContainer(overrides: [
      appStatusProvider.overrideWith((ref) async => status),
    ]);
    addTearDown(container.dispose);
    await container.read(appStatusProvider.future);
    return container.read(handsFreeAllowedProvider);
  }

  test('서버가 handsfree_enabled=false면 막는다', () async {
    expect(
      await allowedWith(const AppStatus(flags: {RemoteFlags.handsFree: false})),
      isFalse,
    );
  });

  test('서버에 값이 없으면 쓸 수 있다', () async {
    expect(await allowedWith(const AppStatus()), isTrue);
  });

  test('상태를 못 받았으면(null) 쓸 수 있다', () async {
    expect(await allowedWith(null), isTrue);
  });

  test('조회가 끝나기 전에도 쓸 수 있다', () {
    final pending = Completer<AppStatus?>(); // 끝나지 않는 조회
    final container = ProviderContainer(overrides: [
      appStatusProvider.overrideWith((ref) => pending.future),
    ]);
    addTearDown(container.dispose);
    expect(container.read(handsFreeAllowedProvider), isTrue);
  });
}
