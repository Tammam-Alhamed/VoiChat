import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailOtpParams {
  final String email;
  final String otp;

  const VerifyEmailOtpParams({required this.email, required this.otp});
}

/// Signs in with the code sent to an email address.
class VerifyEmailOtp extends UseCase<AuthSession, VerifyEmailOtpParams> {
  final AuthRepository _repository;

  const VerifyEmailOtp(this._repository);

  @override
  Future<Result<AuthSession>> call(VerifyEmailOtpParams params) {
    return _repository.verifyEmailOtp(email: params.email, otp: params.otp);
  }
}
