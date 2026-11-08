import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/recent_calls_repository.dart';

/// Removes calls from the signed-in user's history in one request.
class DeleteCallHistory extends UseCase<void, List<String>> {
  final RecentCallsRepository _repository;

  const DeleteCallHistory(this._repository);

  @override
  Future<Result<void>> call(List<String> callIds) {
    return _repository.deleteCalls(callIds);
  }
}
