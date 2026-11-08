import 'package:flutter/foundation.dart';

import '../../../../core/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/auth_failure_codes.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/google_auth_data_source.dart';
import '../models/auth_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  /// Must match the message the server sends when an email is not
  /// registered (or not linked to Google yet). Email OTP is login only, so
  /// this is how that rejection is told apart from other errors.
  static const String _emailNotRegisteredMessage =
      'No account registered with this email. Please sign up with Continue with Google first.';

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final GoogleAuthDataSource _google;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required GoogleAuthDataSource google,
  }) : _remote = remote,
       _local = local,
       _google = google;

  /// Stores the tokens and user of a successful sign-in response.
  AuthSession _saveSession(AuthResponseModel response) {
    if (!response.hasSession) {
      throw ServerException(
        code: Constants.invalidResponse,
        message: response.message ?? 'Invalid response from server',
      );
    }
    _local.saveSession(
      accessToken: response.accessToken!,
      refreshToken: response.refreshToken,
      deviceId: response.deviceId,
      user: response.user,
      markLoggedIn: !response.isNewUser,
    );
    return AuthSession(isNewUser: response.isNewUser);
  }

  @override
  Future<Result<void>> sendPhoneOtp(String phone) {
    return guardResult(() => _remote.sendPhoneOtp(phone));
  }

  @override
  Future<Result<AuthSession>> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) {
    return guardResult(
      () async => _saveSession(await _remote.verifyPhoneOtp(phone, otp)),
    );
  }

  @override
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    String? name,
  }) async {
    final result = await guardResult(() async {
      final response = await _remote.loginWithEmail(email, name: name);
      if (response.success && response.hasData && response.requiresOtp) {
        return const AuthSession(requiresOtp: true);
      }
      return _saveSession(response);
    });

    final failure = result.failureOrNull;
    if (failure != null && failure.message == _emailNotRegisteredMessage) {
      return Err(
        Failure(
          code: AuthFailureCodes.emailNotRegistered,
          message: failure.message,
        ),
      );
    }
    return result;
  }

  @override
  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String otp,
  }) {
    return guardResult(
      () async => _saveSession(await _remote.verifyEmailOtp(email, otp)),
    );
  }

  @override
  Future<Result<AuthSession?>> loginWithGoogle() async {
    try {
      final idToken = await _google.signIn();
      if (idToken == null) return const Ok(null);
      return Ok(_saveSession(await _remote.loginWithGoogle(idToken)));
    } on ServerException catch (e) {
      return Err(Failure(code: e.code, message: e.message));
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in error: $e');
      return Err(
        Failure(
          code: Constants.unKnownError,
          message: 'Google sign-in failed. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> completeProfile({
    required String name,
    DateTime? birthday,
  }) {
    return guardResult(() async {
      final profile = <String, dynamic>{'name': name};
      if (birthday != null) {
        profile['birthdate'] = birthday.toIso8601String().split('T')[0];
      }

      final user = await _remote.completeProfile(profile);
      _local.setLoggedIn(true);
      if (user != null) _local.saveUser(user);
    });
  }

  @override
  Future<Result<bool>> refreshAccessToken() {
    return guardResult(() async {
      final refreshToken = _local.getRefreshToken();
      if (refreshToken == null) return false;

      final tokens = await _remote.refreshToken(refreshToken);
      if (tokens == null) return false;

      _local.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
      return true;
    });
  }

  @override
  Future<Result<void>> logout() {
    return guardResult(() => _remote.logout(fcmToken: _local.getFcmToken()));
  }
}
