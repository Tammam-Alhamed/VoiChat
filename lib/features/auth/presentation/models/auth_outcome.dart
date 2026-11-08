/// What a sign-in attempt means for the screen that started it.
class AuthOutcome {
  final bool success;
  final bool isNewUser;

  /// The login continues on the OTP screen (a code was emailed).
  final bool requiresOtp;

  /// The email is not linked to any account (email login only).
  final bool notRegistered;

  const AuthOutcome({
    required this.success,
    this.isNewUser = false,
    this.requiresOtp = false,
    this.notRegistered = false,
  });

  const AuthOutcome.failed({this.notRegistered = false})
    : success = false,
      isNewUser = false,
      requiresOtp = false;
}
