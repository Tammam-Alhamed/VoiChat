import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/live_session_access.dart';
import '../repositories/live_repository.dart';

/// Joins someone else's live room as a viewer.
class JoinLive extends UseCase<LiveSessionAccess, String> {
  final LiveRepository _repository;

  const JoinLive(this._repository);

  @override
  Future<Result<LiveSessionAccess>> call(String liveId) {
    return _repository.joinLive(liveId);
  }
}
