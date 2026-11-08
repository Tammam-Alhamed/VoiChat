import '../error/result.dart';

/// Contract for a single application action. Each use case does one thing,
/// depends only on domain repositories and returns a [Result].
abstract class UseCase<T, Params> {
  const UseCase();

  Future<Result<T>> call(Params params);
}

/// Parameter placeholder for use cases that need no input.
class NoParams {
  const NoParams();
}

/// Contract for an action that completes synchronously, such as reading a
/// value that is already cached on the device.
abstract class SyncUseCase<T, Params> {
  const SyncUseCase();

  T call(Params params);
}
