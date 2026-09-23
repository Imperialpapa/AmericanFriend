import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eng_friend/core/constants/app_constants.dart';

/// 신고 사유. 서버(`backend/api/v1/report.ts`)의 REASONS와 같은 값이어야 한다.
enum ReportReason { harmful, incorrect, other }

/// AI 응답 신고 1건.
class AiReport {
  final ReportReason reason;
  final String message;
  final String? prevUser;
  final String? provider;
  final String? model;
  final String? locale;

  const AiReport({
    required this.reason,
    required this.message,
    this.prevUser,
    this.provider,
    this.model,
    this.locale,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason.name,
        'message': message,
        if (prevUser != null) 'prevUser': prevUser,
        if (provider != null) 'provider': provider,
        if (model != null) 'model': model,
        'appVersion': AppConstants.appVersion,
        if (locale != null) 'locale': locale,
      };
}

enum ReportResult {
  sent,

  /// 지금은 못 보냈지만 큐에 넣었다 — 다음 앱 시작 때 다시 보낸다.
  queued,

  /// 서버가 요청 자체를 거절했다(400 등). 다시 보내도 같다.
  rejected,
}

const _pendingKey = 'pending_ai_reports';
const _maxPending = 20;

/// 큐에 남아 있을 수 있는 최대 시작 횟수. 서버가 계속 죽어 있어도 큐가 영원히 남지 않게.
const _maxAttempts = 5;

/// Play 'AI 생성 콘텐츠' 정책: 앱을 떠나지 않고 신고할 수 있어야 한다(tobe P-01).
///
/// BYOK 사용자도 무료 티어 프록시로 보낸다 — 신고 수신처는 제공자와 무관하게 하나다.
/// 인증은 채팅과 같은 `x-device-id`(freeTierDeviceId). BYOK 키는 절대 보내지 않는다.
class ReportService {
  final Dio _dio;
  final SharedPreferences _prefs;

  ReportService({
    required String baseUrl,
    required SharedPreferences prefs,
    Dio? dio,
  })  : _prefs = prefs,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'KoreanFriend/${AppConstants.appVersion}',
              },
            ));

  /// 보내고, 실패하면 큐에 넣는다. 예외를 던지지 않는다.
  Future<ReportResult> submit(AiReport report, {required String deviceId}) async {
    final body = report.toJson();
    // id가 비면 서버가 400으로 거절해 신고가 사라진다 — 보내지 말고 큐에 둔다.
    final result = deviceId.isEmpty
        ? _PostResult.retryable
        : await _post(body, deviceId);
    if (result == _PostResult.retryable) {
      await _enqueue(body);
      return ReportResult.queued;
    }
    return result == _PostResult.ok ? ReportResult.sent : ReportResult.rejected;
  }

  /// 앱 시작 시 1회: 큐에 남은 신고를 다시 보낸다.
  Future<void> flushPending({required String deviceId}) async {
    if (deviceId.isEmpty) return;
    final pending = _readPending();
    if (pending.isEmpty) return;
    // 먼저 큐를 비워 둔다 — 재전송 도중 사용자가 새로 신고해 큐에 들어간 항목을 덮어쓰지 않게.
    await _writePending(const []);
    final keep = <Map<String, dynamic>>[];
    for (final item in pending) {
      final body = item['body'];
      if (body is! Map<String, dynamic>) continue;
      final attempts = (item['attempts'] as num?)?.toInt() ?? 0;
      final result = await _post(body, deviceId);
      if (result == _PostResult.retryable && attempts + 1 < _maxAttempts) {
        keep.add({'body': body, 'attempts': attempts + 1});
      }
    }
    await _writePending(_capped([...keep, ..._readPending()]));
    debugPrint('[Report] flushed ${pending.length - keep.length}, kept ${keep.length}');
  }

  @visibleForTesting
  int get pendingCount => _readPending().length;

  Future<_PostResult> _post(Map<String, dynamic> body, String deviceId) async {
    try {
      await _dio.post(
        '/api/v1/report',
        data: body,
        options: Options(headers: {'x-device-id': deviceId}),
      );
      return _PostResult.ok;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      debugPrint('[Report] send failed: $status ${e.type.name}');
      // 429(하루 한도)·5xx·네트워크는 나중에 될 수 있다. 나머지 4xx는 다시 보내도 같다.
      if (status == null || status == 429 || status >= 500) {
        return _PostResult.retryable;
      }
      return _PostResult.rejected;
    } catch (e) {
      debugPrint('[Report] send failed: $e');
      return _PostResult.retryable;
    }
  }

  List<Map<String, dynamic>> _readPending() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePending(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      await _prefs.remove(_pendingKey);
    } else {
      await _prefs.setString(_pendingKey, jsonEncode(items));
    }
  }

  Future<void> _enqueue(Map<String, dynamic> body) async {
    await _writePending(
        _capped([..._readPending(), {'body': body, 'attempts': 0}]));
  }

  /// 오래된 것부터 버린다 — 큐가 prefs를 불리지 않게.
  List<Map<String, dynamic>> _capped(List<Map<String, dynamic>> items) =>
      items.length > _maxPending
          ? items.sublist(items.length - _maxPending)
          : items;
}

enum _PostResult { ok, retryable, rejected }
