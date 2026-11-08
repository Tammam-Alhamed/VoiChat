import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmailParams {
  final String email;
  final String? name;

  const LoginWithEmailParams({required this.email, this.name});
}

/// Starts an email login, which usually continues with an emailed code.
class LoginWithEmail extends UseCase<AuthSession, LoginWithEmailParams> {
  final AuthRepository _repository;

  const LoginWithEmail(this._repository);

  @override
  Future<Result<AuthSession>> call(LoginWithEmailParams params) {
    return _repository.loginWithEmail(email: params.email, name: params.name);
  }
}
