import 'exceptions.dart';
import 'failure.dart';

/// The outcome of a repository or use case call: either [Ok] with a value or
/// [Err] with a [Failure]. Controllers branch on it with [fold] or a
/// `switch`, so error handling is explicit and never relies on exceptions.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value when this is [Ok], otherwise `null`.
  T? get dataOrNull => switch (this) {
    Ok<T>(:final data) => data,
    Err<T>() => null,
  };

  /// The failure when this is [Err], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>(R Function(Failure failure) onErr, R Function(T data) onOk) =>
      switch (this) {
        Ok<T>(:final data) => onOk(data),
        Err<T>(:final failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

/// Runs [body] and converts its outcome into a [Result]. Every repository
/// implementation goes through this, so a [ServerException] becomes a
/// [Failure] with the same code and message, and any other error becomes an
/// unexpected failure instead of crashing the caller.
Future<Result<T>> guardResult<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on ServerException catch (e) {
    return Err(Failure(code: e.code, message: e.message));
  } on CacheException catch (e) {
    return Err(Failure.unexpected(e.message));
  } catch (e) {
    return Err(Failure.unexpected(e));
  }
}
