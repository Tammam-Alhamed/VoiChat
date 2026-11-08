import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Sends a one-time code to [phone] by WhatsApp.
class SendPhoneOtp extends UseCase<void, String> {
  final AuthRepository _repository;

  const SendPhoneOtp(this._repository);

  @override
  Future<Result<void>> call(String phone) => _repository.sendPhoneOtp(phone);
}
