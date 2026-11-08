import '../../../../core/error/result.dart';
import '../../domain/entities/call_history.dart';
import '../../domain/repositories/recent_calls_repository.dart';
import '../datasources/recent_calls_remote_data_source.dart';

class RecentCallsRepositoryImpl implements RecentCallsRepository {
  final RecentCallsRemoteDataSource _remote;

  RecentCallsRepositoryImpl({required RecentCallsRemoteDataSource remote})
    : _remote = remote;

  @override
  Future<Result<List<CallHistory>>> getCallHistory() {
    return guardResult(_remote.getCallHistory);
  }

  @override
  Future<Result<void>> deleteCalls(List<String> callIds) {
    return guardResult(() => _remote.deleteCalls(callIds));
  }
}
