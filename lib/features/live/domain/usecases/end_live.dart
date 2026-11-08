import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/live_repository.dart';

/// Ends the host's current live session on the server.
class EndLive extends UseCase<void, NoParams> {
  final LiveRepository _repository;

  const EndLive(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.endLive();
}
