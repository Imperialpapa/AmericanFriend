import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eng_friend/core/constants/app_constants.dart';
import 'package:eng_friend/services/status/app_status.dart';

const _cachedStatusKey = 'app_status_cached_json';
const _dismissedNoticeKey = 'app_status_dismissed_notice_id';

/// 서버에서 앱 상태/공지를 가져온다.
///
/// 설계 원칙:
/// - **절대 앱 시작을 막지 않는다.** 실패하면 조용히 캐시를 쓰거나 아무것도 안 한다.
///   상태 확인 실패로 앱을 못 쓰게 되면 본말전도다.
/// - 응답은 캐시해서 오프라인/서버 장애 시에도 마지막 공지를 유지한다.
class AppStatusService {
  final Dio _dio;
  final SharedPreferences _prefs;

  AppStatusService({required String baseUrl, required SharedPreferences prefs})
      : _prefs = prefs,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          headers: {'User-Agent': 'KoreanFriend/${AppConstants.appVersion}'},
        ));

  /// 서버 조회 → 실패 시 캐시. 둘 다 없으면 null.
  Future<AppStatus?> fetch() async {
    try {
      final res = await _dio.get('/api/v1/status');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        await _prefs.setString(_cachedStatusKey, jsonEncode(data));
        return AppStatus.fromJson(data);
      }
    } catch (e) {
      debugPrint('[AppStatus] fetch failed: $e');
    }
    return _cached();
  }

  AppStatus? _cached() {
    final raw = _prefs.getString(_cachedStatusKey);
    if (raw == null) return null;
    try {
      return AppStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool isNoticeDismissed(String noticeId) =>
      _prefs.getString(_dismissedNoticeKey) == noticeId;

  Future<void> dismissNotice(String noticeId) async {
    await _prefs.setString(_dismissedNoticeKey, noticeId);
  }
}
