import '../../../../core/usecase/usecase.dart';
import '../entities/session_data.dart';
import '../repositories/session_repository.dart';

/// Returns the last session snapshot stored on the device, if any.
class GetCachedSession extends SyncUseCase<SessionData?, NoParams> {
  final SessionRepository _repository;

  const GetCachedSession(this._repository);

  @override
  SessionData? call(NoParams params) => _repository.getCachedSession();
}
