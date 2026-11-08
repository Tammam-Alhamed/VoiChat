import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/session_repository.dart';

/// Registers this device's push token for the signed-in account.
class SyncFcmToken extends UseCase<void, NoParams> {
  final SessionRepository _repository;

  const SyncFcmToken(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.syncFcmToken();
}
