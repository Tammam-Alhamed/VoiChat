import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Signs in with a Google account. Yields null when the user cancels.
class LoginWithGoogle extends UseCase<AuthSession?, NoParams> {
  final AuthRepository _repository;

  const LoginWithGoogle(this._repository);

  @override
  Future<Result<AuthSession?>> call(NoParams params) {
    return _repository.loginWithGoogle();
  }
}
