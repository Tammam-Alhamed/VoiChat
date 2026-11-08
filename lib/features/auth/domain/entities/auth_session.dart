/// Result of a successful sign-in step.
class AuthSession {
  /// True when the account was just created and still needs its profile
  /// (name and birthdate) before the user is considered logged in.
  final bool isNewUser;

  /// True when the server sent a one-time code by email and the login must
  /// continue on the OTP screen. No tokens are stored in that case.
  final bool requiresOtp;

  const AuthSession({this.isNewUser = false, this.requiresOtp = false});
}
