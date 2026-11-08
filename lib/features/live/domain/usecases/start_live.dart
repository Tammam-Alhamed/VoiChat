import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/live_session_access.dart';
import '../repositories/live_repository.dart';

class StartLiveParams {
  final String title;
  final int? goalAmount;

  const StartLiveParams({required this.title, this.goalAmount});
}

/// Starts a new broadcast as host, optionally with a gift goal.
class StartLive extends UseCase<LiveSessionAccess, StartLiveParams> {
  final LiveRepository _repository;

  const StartLive(this._repository);

  @override
  Future<Result<LiveSessionAccess>> call(StartLiveParams params) {
    return _repository.startLive(
      title: params.title,
      goalAmount: params.goalAmount,
    );
  }
}
