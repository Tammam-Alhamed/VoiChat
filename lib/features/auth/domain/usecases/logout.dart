import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Signs this device out on the server.
class Logout extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  const Logout(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}
