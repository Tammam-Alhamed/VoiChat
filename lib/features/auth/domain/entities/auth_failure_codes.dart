/// Failure codes specific to authentication, used alongside the generic
/// codes in `Constants`.
class AuthFailureCodes {
  AuthFailureCodes._();

  /// Email OTP is login only: the email is not linked to any account yet.
  static const int emailNotRegistered = 460;
}
