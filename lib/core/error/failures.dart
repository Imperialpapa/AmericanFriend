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

class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}
