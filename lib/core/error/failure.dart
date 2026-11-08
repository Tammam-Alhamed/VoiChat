import '../constants.dart';

/// Domain-level error returned to the presentation layer inside a
/// [Result]. It never carries framework or transport types, only a numeric
/// [code] (see `Constants`) and a human readable [message].
class Failure {
  final int code;
  final String message;

  const Failure({required this.code, required this.message});

  /// Builds a failure for an unexpected error (parsing, platform, ...).
  factory Failure.unexpected(Object error) =>
      Failure(code: Constants.unKnownError, message: error.toString());

  bool get isUnauthorized => code == Constants.unAuthorized;
  bool get isNoInternet => code == Constants.noInternet;

  @override
  String toString() => 'Failure($code): $message';
}
