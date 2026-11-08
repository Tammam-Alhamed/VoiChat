import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_status.dart';
import '../repositories/session_repository.dart';

/// Validates the current device and token against the server.
class CheckAppStatus extends UseCase<AppStatus, NoParams> {
  final SessionRepository _repository;

  const CheckAppStatus(this._repository);

  @override
  Future<Result<AppStatus>> call(NoParams params) {
    return _repository.checkAppStatus();
  }
}
