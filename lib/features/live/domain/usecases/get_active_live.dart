import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/live_session_access.dart';
import '../repositories/live_repository.dart';

/// The host's still-running live session, if any.
class GetActiveLive extends UseCase<LiveSessionAccess?, NoParams> {
  final LiveRepository _repository;

  const GetActiveLive(this._repository);

  @override
  Future<Result<LiveSessionAccess?>> call(NoParams params) {
    return _repository.getActiveLive();
  }
}
