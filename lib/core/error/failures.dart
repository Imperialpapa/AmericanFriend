sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AiServiceFailure extends Failure {
  const AiServiceFailure(super.message);
}

class SttFailure extends Failure {
  const SttFailure(super.message);
}

class TtsFailure extends Failure {
  const TtsFailure(super.message);
}

/// 무료 티어 일일 한도 소진.
/// 네트워크 오류와 반드시 구분해야 한다 — 재시도해도 소용없고, 핸즈프리 같은
/// 자동 재시도 루프는 즉시 멈춰야 하며, 사용자에겐 API 키 등록을 안내해야 한다.
class RateLimitFailure extends Failure {
  final int limit;
  final int used;
  final String? resetAt;

  const RateLimitFailure(
    super.message, {
    required this.limit,
    required this.used,
    this.resetAt,
  });
}

/// 무료 티어 프록시/업스트림 장애. 사용자 잘못이 아니며 본인 API 키로 우회 가능.
class FreeTierUnavailableFailure extends Failure {
  final int? statusCode;
  final bool isNetwork;

  const FreeTierUnavailableFailure(
    super.message, {
    this.statusCode,
    this.isNetwork = false,
  });
}

/// AI가 보여줄 답변을 내지 않았다(빈 스트림, 안전 차단).
/// 빈 문자열을 정상 응답으로 히스토리에 넣으면 이후 Claude 요청이 매번 400이 된다.
class EmptyResponseFailure extends Failure {
  const EmptyResponseFailure(super.message);
}

class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}
