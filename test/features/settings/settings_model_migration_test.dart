import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eng_friend/features/settings/presentation/providers/settings_provider.dart';
import 'package:eng_friend/services/ai/ai_provider_type.dart';

/// 상태 엔드포인트 없이 load()만으로 내장 매핑이 적용되는지(tobe A-02).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SettingsNotifier, SharedPreferences)> loadWith(
    Map<String, Object> prefsValues,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    FlutterSecureStorage.setMockInitialValues({'claude_api_key': 'k'});
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(const FlutterSecureStorage(), prefs);
    await notifier.load();
    return (notifier, prefs);
  }

  test('저장된 은퇴 ID를 시작 시 교정하고 prefs에도 쓴다', () async {
    final (notifier, prefs) = await loadWith({
      'ai_provider': 'claude',
      'claude_model_id': 'claude-sonnet-4-20250514',
      'openai_model_id': 'gpt-4.1-nano',
      'gemini_model_id': 'gemini-2.5-pro',
    });

    expect(notifier.state.claudeModelId, 'claude-sonnet-5');
    expect(notifier.state.openaiModelId, 'gpt-4o-mini');
    expect(notifier.state.geminiModelId, 'gemini-3.8-flash');
    expect(prefs.getString('claude_model_id'), 'claude-sonnet-5');
    expect(prefs.getString('openai_model_id'), 'gpt-4o-mini');
    expect(prefs.getString('gemini_model_id'), 'gemini-3.8-flash');
    expect(notifier.state.activeModelId, 'claude-sonnet-5');
  });

  test('모델을 고른 적 없으면 아무것도 쓰지 않고 현재 기본값을 쓴다', () async {
    final (notifier, prefs) = await loadWith({'ai_provider': 'claude'});

    expect(prefs.getString('claude_model_id'), isNull);
    expect(notifier.state.claudeModelId, isNull);
    expect(notifier.state.activeModelId, AiProviderType.claude.defaultModelId);
  });

  test('서버 매핑은 카탈로그에 있는 대상만 반영한다', () async {
    final (notifier, prefs) = await loadWith({
      'ai_provider': 'claude',
      'claude_model_id': 'claude-haiku-4-5-20251001',
    });

    await notifier.applyModelMigrations(
        {'claude-haiku-4-5-20251001': 'claude-haiku-9'});
    expect(notifier.state.claudeModelId, 'claude-haiku-4-5-20251001');

    await notifier.applyModelMigrations(
        {'claude-haiku-4-5-20251001': 'claude-sonnet-5'});
    expect(notifier.state.claudeModelId, 'claude-sonnet-5');
    expect(prefs.getString('claude_model_id'), 'claude-sonnet-5');
  });
}
