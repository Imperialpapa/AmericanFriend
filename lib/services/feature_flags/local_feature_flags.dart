import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/services/feature_flags/feature_flag_service.dart';
import 'package:eng_friend/services/feature_flags/flags.dart';

class LocalFeatureFlags implements FeatureFlagService {
  final SharedPreferences _prefs;

  LocalFeatureFlags(this._prefs);

  @override
  Future<void> initialize() async {
    // 기본값 설정 (아직 없는 플래그만)
    for (final entry in Flags.defaults.entries) {
      if (!_prefs.containsKey(entry.key)) {
        await _prefs.setBool(entry.key, entry.value);
      }
    }
  }

  @override
  bool isEnabled(String flag) {
    return _prefs.getBool(flag) ?? Flags.defaults[flag] ?? false;
  }

  @override
  Future<void> setFlag(String flag, bool value) async {
    await _prefs.setBool(flag, value);
  }
}
