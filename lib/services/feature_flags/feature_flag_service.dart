abstract class FeatureFlagService {
  bool isEnabled(String flag);
  Future<void> setFlag(String flag, bool value);
  Future<void> initialize();
}
