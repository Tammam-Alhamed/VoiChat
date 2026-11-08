import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpParams {
  final String phone;
  final String otp;

  const VerifyPhoneOtpParams({required this.phone, required this.otp});
}

/// Signs in with the code sent to a phone number.
class VerifyPhoneOtp extends UseCase<AuthSession, VerifyPhoneOtpParams> {
  final AuthRepository _repository;

  const VerifyPhoneOtp(this._repository);

  @override
  Future<Result<AuthSession>> call(VerifyPhoneOtpParams params) {
    return _repository.verifyPhoneOtp(phone: params.phone, otp: params.otp);
  }
}
