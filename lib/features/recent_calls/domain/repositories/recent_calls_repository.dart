import '../../../../core/error/result.dart';
import '../entities/call_history.dart';

/// Contract for the signed-in user's call history.
abstract class RecentCallsRepository {
  Future<Result<List<CallHistory>>> getCallHistory();

  Future<Result<void>> deleteCalls(List<String> callIds);
}
