import '../../../../core/usecase/usecase.dart';
import '../entities/session_data.dart';
import '../repositories/session_repository.dart';

/// Persists the in-memory session so the next launch can render instantly.
class CacheSession extends SyncUseCase<void, SessionData> {
  final SessionRepository _repository;

  const CacheSession(this._repository);

  @override
  void call(SessionData params) => _repository.cacheSession(params);
}
