import '../../../../core/usecase/usecase.dart';
import '../repositories/session_repository.dart';

/// Whether a signed-in account (login flag and token) is stored locally.
class HasStoredLogin extends SyncUseCase<bool, NoParams> {
  final SessionRepository _repository;

  const HasStoredLogin(this._repository);

  @override
  bool call(NoParams params) => _repository.hasStoredLogin();
}
