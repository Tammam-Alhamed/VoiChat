import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CompleteProfileParams {
  final String name;
  final DateTime? birthday;

  const CompleteProfileParams({required this.name, this.birthday});
}

/// Last step of sign-up: saves the name and birthdate of a new account.
class CompleteProfile extends UseCase<void, CompleteProfileParams> {
  final AuthRepository _repository;

  const CompleteProfile(this._repository);

  @override
  Future<Result<void>> call(CompleteProfileParams params) {
    return _repository.completeProfile(
      name: params.name,
      birthday: params.birthday,
    );
  }
}
