import 'package:get/get.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_failure_codes.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/complete_profile.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/refresh_access_token.dart';
import '../../domain/usecases/send_phone_otp.dart';
import '../../domain/usecases/verify_email_otp.dart';
import '../../domain/usecases/verify_phone_otp.dart';
import '../models/auth_outcome.dart';

/// Drives the login and sign-up screens: phone OTP, email OTP, Google and
/// the profile step for new accounts. Keeps the loading flag, the last
/// error and the data collected across the sign-up screens.
class AuthController extends GetxController {
  final SendPhoneOtp _sendPhoneOtp;
  final VerifyPhoneOtp _verifyPhoneOtp;
  final LoginWithEmail _loginWithEmail;
  final VerifyEmailOtp _verifyEmailOtp;
  final LoginWithGoogle _loginWithGoogle;
  final CompleteProfile _completeProfile;
  final RefreshAccessToken _refreshAccessToken;

  AuthController({
    required SendPhoneOtp sendPhoneOtp,
    required VerifyPhoneOtp verifyPhoneOtp,
    required LoginWithEmail loginWithEmail,
    required VerifyEmailOtp verifyEmailOtp,
    required LoginWithGoogle loginWithGoogle,
    required CompleteProfile completeProfile,
    required RefreshAccessToken refreshAccessToken,
  }) : _sendPhoneOtp = sendPhoneOtp,
       _verifyPhoneOtp = verifyPhoneOtp,
       _loginWithEmail = loginWithEmail,
       _verifyEmailOtp = verifyEmailOtp,
       _loginWithGoogle = loginWithGoogle,
       _completeProfile = completeProfile,
       _refreshAccessToken = refreshAccessToken;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Whether the last verified user is a new account (needs profile setup).
  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  /// Display name collected on the name screen during sign-up.
  String? _pendingName;
  String? get pendingName => _pendingName;

  /// Birthdate collected on the birthday screen during sign-up.
  DateTime? _pendingBirthday;
  DateTime? get pendingBirthday => _pendingBirthday;

  /// Phone number of the current phone login.
  String? _currentPhone;
  String? get currentPhone => _currentPhone;

  void _setLoading(bool value) {
    _isLoading = value;
    update();
  }

  void _setError(String? message) {
    _errorMessage = message;
    update();
  }

  void clearError() => _setError(null);

  void setPendingName(String name) => _pendingName = name;

  void setPendingBirthday(DateTime birthday) => _pendingBirthday = birthday;

  void _startRequest() {
    _setLoading(true);
    _setError(null);
  }

  /// Maps a sign-in result to what the screen needs and records the error.
  AuthOutcome _toOutcome(Result<AuthSession> result) {
    switch (result) {
      case Ok(data: final session):
        _isNewUser = session.isNewUser;
        return AuthOutcome(success: true, isNewUser: session.isNewUser);
      case Err(:final failure):
        _setError(failure.message);
        return const AuthOutcome.failed();
    }
  }

  /// Phone login, step 1: sends the code to [phone].
  Future<bool> sendOtp(String phone) async {
    _startRequest();
    _currentPhone = phone;

    final result = await _sendPhoneOtp(phone);
    _setLoading(false);

    if (result case Err(:final failure)) {
      _setError(failure.message);
      return false;
    }
    return true;
  }

  /// Phone login, step 2: verifies the code and signs the user in.
  Future<AuthOutcome> verifyOtp(String phone, String otp) async {
    _startRequest();
    final result = await _verifyPhoneOtp(
      VerifyPhoneOtpParams(phone: phone, otp: otp),
    );
    _setLoading(false);
    return _toOutcome(result);
  }

  /// Saves the name and birthdate of a new account (last sign-up step).
  /// On failure (for example under 18) the user stays on the birthday screen
  /// with the server's message.
  Future<bool> completeProfile({
    required String name,
    DateTime? birthday,
  }) async {
    _startRequest();
    final result = await _completeProfile(
      CompleteProfileParams(name: name, birthday: birthday),
    );
    _setLoading(false);

    switch (result) {
      case Ok():
        _isNewUser = false;
        return true;
      case Err(:final failure):
        _setError(failure.message);
        return false;
    }
  }

  /// Opens the Google account picker and signs in with the chosen account.
  Future<AuthOutcome> loginWithGoogle() async {
    _startRequest();
    final result = await _loginWithGoogle(const NoParams());
    _setLoading(false);

    switch (result) {
      case Ok(data: null):
        return const AuthOutcome.failed();
      case Ok(data: final AuthSession session):
        return _toOutcome(Ok(session));
      case Err(:final failure):
        _setError(failure.message);
        return const AuthOutcome.failed();
    }
  }

  /// Email login. Usually answers with `requiresOtp`, after which the code
  /// is verified with [verifyEmailOtp].
  Future<AuthOutcome> loginWithEmail(String email, {String? name}) async {
    _startRequest();
    final result = await _loginWithEmail(
      LoginWithEmailParams(email: email, name: name),
    );
    _setLoading(false);

    switch (result) {
      case Ok(data: AuthSession(requiresOtp: true)):
        return const AuthOutcome(success: true, requiresOtp: true);
      case Ok():
        return _toOutcome(result);
      case Err(:final Failure failure):
        _setError(failure.message);
        return AuthOutcome.failed(
          notRegistered: failure.code == AuthFailureCodes.emailNotRegistered,
        );
    }
  }

  Future<AuthOutcome> verifyEmailOtp(String email, String otp) async {
    _startRequest();
    final result = await _verifyEmailOtp(
      VerifyEmailOtpParams(email: email, otp: otp),
    );
    _setLoading(false);
    return _toOutcome(result);
  }

  Future<bool> refreshAccessToken() async {
    final result = await _refreshAccessToken(const NoParams());
    return result.dataOrNull ?? false;
  }

  /// Ends the session everywhere (server, socket, storage, memory) and opens
  /// the login screen.
  Future<void> logout() => SessionManager.endSession();

  /// Clears a half-finished login or sign-up flow (called on logout).
  void resetFlow() {
    _isLoading = false;
    _errorMessage = null;
    _isNewUser = false;
    _pendingName = null;
    _pendingBirthday = null;
    _currentPhone = null;
  }
}
