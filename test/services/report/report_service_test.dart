import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/services/report/report_service.dart';

/// 네트워크 없이 상태 코드만 흉내 낸다. status 0 = 연결 실패.
class _FakeAdapter implements HttpClientAdapter {
  int status;
  final requests = <RequestOptions>[];
  _FakeAdapter(this.status);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (status == 0) {
      throw DioException.connectionError(
          requestOptions: options, reason: 'offline');
    }
    return ResponseBody.fromString(
      jsonEncode(status == 200 ? {'ok': true} : {'error': {}}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _report = AiReport(
  reason: ReportReason.incorrect,
  message: 'Paris is in Germany.',
  prevUser: 'Where is Paris?',
  provider: 'freeTier',
  model: 'free',
);

void main() {
  late SharedPreferences prefs;
  late _FakeAdapter adapter;
  late ReportService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    adapter = _FakeAdapter(200);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    service = ReportService(baseUrl: '', prefs: prefs, dio: dio);
  });

  test('성공하면 sent, 기기 id 헤더와 서버 계약 필드를 보낸다', () async {
    final r = await service.submit(_report, deviceId: 'device-1234');
    expect(r, ReportResult.sent);
    expect(service.pendingCount, 0);

    final req = adapter.requests.single;
    expect(req.path, '/api/v1/report');
    expect(req.headers['x-device-id'], 'device-1234');
    final body = req.data as Map<String, dynamic>;
    expect(body['reason'], 'incorrect');
    expect(body['message'], 'Paris is in Germany.');
    expect(body['prevUser'], 'Where is Paris?');
    expect(body['appVersion'], isNotEmpty);
  });

  test('네트워크 실패는 큐에 넣고, 다음 시작 때 보내면 큐가 빈다', () async {
    adapter.status = 0;
    expect(await service.submit(_report, deviceId: 'device-1234'),
        ReportResult.queued);
    expect(service.pendingCount, 1);

    adapter.status = 200;
    await service.flushPending(deviceId: 'device-1234');
    expect(service.pendingCount, 0);
    expect(adapter.requests, hasLength(2));
  });

  test('5xx·429는 재시도 대상, 400은 버린다', () async {
    adapter.status = 503;
    expect(await service.submit(_report, deviceId: 'd-12345678'),
        ReportResult.queued);
    adapter.status = 429;
    expect(await service.submit(_report, deviceId: 'd-12345678'),
        ReportResult.queued);
    adapter.status = 400;
    expect(await service.submit(_report, deviceId: 'd-12345678'),
        ReportResult.rejected);
    expect(service.pendingCount, 2);

    // 재전송에서 400이 나면 다시 보내도 같으니 큐에서 뺀다.
    await service.flushPending(deviceId: 'd-12345678');
    expect(service.pendingCount, 0);
  });

  test('계속 실패하면 몇 번의 시작 뒤 포기한다 — 큐가 영원히 남지 않는다', () async {
    adapter.status = 0;
    await service.submit(_report, deviceId: 'd-12345678');
    for (var i = 0; i < 10; i++) {
      await service.flushPending(deviceId: 'd-12345678');
    }
    expect(service.pendingCount, 0);
  });

  test('기기 id가 비어 있으면 보내지 않고 큐에 둔다', () async {
    expect(await service.submit(_report, deviceId: ''), ReportResult.queued);
    expect(adapter.requests, isEmpty);
    await service.flushPending(deviceId: '');
    expect(service.pendingCount, 1);
  });

  test('큐는 최근 20건까지만 보관한다', () async {
    adapter.status = 0;
    for (var i = 0; i < 25; i++) {
      await service.submit(_report, deviceId: 'd-12345678');
    }
    expect(service.pendingCount, 20);
  });
}
