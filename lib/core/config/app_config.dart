import 'package:eng_friend/core/config/flavor.dart';

class AppConfig {
  final Flavor flavor;
  final String claudeApiKey;
  final String openaiApiKey;

  const AppConfig({
    required this.flavor,
    required this.claudeApiKey,
    required this.openaiApiKey,
  });
}
