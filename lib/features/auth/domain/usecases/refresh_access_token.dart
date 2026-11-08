import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Renews the access token with the stored refresh token.
class RefreshAccessToken extends UseCase<bool, NoParams> {
  final AuthRepository _repository;

  const RefreshAccessToken(this._repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return _repository.refreshAccessToken();
  }
}
