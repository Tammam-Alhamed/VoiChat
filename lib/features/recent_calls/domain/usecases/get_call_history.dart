import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/call_history.dart';
import '../repositories/recent_calls_repository.dart';

/// Loads the signed-in user's call history.
class GetCallHistory extends UseCase<List<CallHistory>, NoParams> {
  final RecentCallsRepository _repository;

  const GetCallHistory(this._repository);

  @override
  Future<Result<List<CallHistory>>> call(NoParams params) {
    return _repository.getCallHistory();
  }
}
