import '../../../../core/error/result.dart';
import '../../domain/entities/live_session_access.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_data_source.dart';

class LiveRepositoryImpl implements LiveRepository {
  final LiveRemoteDataSource _remote;

  LiveRepositoryImpl({required LiveRemoteDataSource remote}) : _remote = remote;

  @override
  Future<Result<LiveSessionAccess>> joinLive(String liveId) {
    return guardResult(() => _remote.joinLive(liveId));
  }

  @override
  Future<Result<LiveSessionAccess>> startLive({
    required String title,
    int? goalAmount,
  }) {
    return guardResult(
      () => _remote.startLive(title: title, goalAmount: goalAmount),
    );
  }

  @override
  Future<Result<LiveSessionAccess?>> getActiveLive() {
    return guardResult(_remote.getActiveLive);
  }

  @override
  Future<Result<void>> endLive() => guardResult(_remote.endLive);
}
