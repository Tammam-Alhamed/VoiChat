import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';

/// Contract for every way a user can sign in, finish sign-up and sign out.
abstract class AuthRepository {
  Future<Result<void>> sendPhoneOtp(String phone);

  Future<Result<AuthSession>> verifyPhoneOtp({
    required String phone,
    required String otp,
  });

  /// Starts an email login. The result has `requiresOtp` set when a code was
  /// emailed; otherwise the user is signed in directly.
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    String? name,
  });

  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String otp,
  });

  /// Runs the native Google sign-in. Returns `Ok(null)` when the user
  /// cancelled the Google dialog.
  Future<Result<AuthSession?>> loginWithGoogle();

  /// Saves the name and birthdate of a newly created account and marks the
  /// user as logged in.
  Future<Result<void>> completeProfile({
    required String name,
    DateTime? birthday,
  });

  /// Exchanges the stored refresh token for a new access token.
  Future<Result<bool>> refreshAccessToken();

  /// Tells the server this device is signing out so it stops sending push
  /// notifications here.
  Future<Result<void>> logout();
}
