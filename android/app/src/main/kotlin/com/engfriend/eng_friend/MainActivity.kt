package com.engfriend.eng_friend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 리마인더 예약에 기기 타임존 ID(예: Asia/Seoul)만 필요해서 플러그인 대신 채널 하나로 받는다.
        // 없으면 tz.local이 UTC라 20:00 설정이 KST 05:00에 울린다(tobe.md L-01).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMEZONE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getLocalTimezone") {
                    result.success(TimeZone.getDefault().id)
                } else {
                    result.notImplemented()
                }
            }
    }

    private companion object {
        const val TIMEZONE_CHANNEL = "com.engfriend.eng_friend/timezone"
    }
}
