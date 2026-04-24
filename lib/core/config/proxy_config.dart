/// Free tier 프록시(Vercel Edge Functions) URL.
///
/// 배포 후 Vercel이 할당한 URL로 교체하세요. 사용자 정의 도메인이 있으면 그 주소로.
/// dart-define으로 덮어쓸 수도 있습니다:
///   flutter build apk --dart-define=FREE_TIER_URL=https://your.vercel.app
class ProxyConfig {
  static const String freeTierBaseUrl = String.fromEnvironment(
    'FREE_TIER_URL',
    defaultValue: 'https://american-friend.vercel.app',
  );
}
