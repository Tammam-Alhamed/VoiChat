import '../../../../core/usecase/usecase.dart';
import '../entities/session_data.dart';
import '../repositories/session_repository.dart';

/// Builds a minimal session from the user saved at login. Last resort when
/// there is no snapshot and the server can't be reached.
class GetStoredUserSession extends SyncUseCase<SessionData?, NoParams> {
  final SessionRepository _repository;

  const GetStoredUserSession(this._repository);

  @override
  SessionData? call(NoParams params) => _repository.getStoredUserSession();
}
