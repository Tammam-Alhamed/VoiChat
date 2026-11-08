import 'dart:convert';

import '../../../../core/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/helpers/device_info_helper.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';
import '../../../../core/utils/api_status.dart';
import '../models/auth_response_model.dart';

/// HTTP calls of the authentication flow. Every method throws a
/// [ServerException] when the request fails.
abstract class AuthRemoteDataSource {
  Future<void> sendPhoneOtp(String phone);

  Future<AuthResponseModel> verifyPhoneOtp(String phone, String otp);

  Future<AuthResponseModel> loginWithEmail(String email, {String? name});

  Future<AuthResponseModel> verifyEmailOtp(String email, String otp);

  Future<AuthResponseModel> loginWithGoogle(String idToken);

  /// Saves the profile and returns the updated user JSON, if any.
  Future<dynamic> completeProfile(Map<String, dynamic> profile);

  /// Returns the new `{accessToken, refreshToken}` pair, or null when the
  /// server did not issue one.
  Future<Map<String, dynamic>?> refreshToken(String refreshToken);

  Future<void> logout({dynamic fcmToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ServiceHelper _serviceHelper;

  AuthRemoteDataSourceImpl({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  /// Decodes a sign-in response, reporting a malformed body with the same
  /// message the user has always seen.
  AuthResponseModel _parseAuth(ApiStatus response) {
    if (response is! Success) throw response.toServerException();
    try {
      final json = jsonDecode(response.data.toString());
      return AuthResponseModel.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      throw ServerException(
        code: Constants.invalidFormat,
        message: 'Failed to parse server response',
      );
    }
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/phone/send-otp',
      data: {'phone': phone},
    );
    response.ensureSuccess();
  }

  @override
  Future<AuthResponseModel> verifyPhoneOtp(String phone, String otp) async {
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/phone/verify',
      data: {'phone': phone, 'otp': otp, 'deviceInfo': deviceInfo},
    );
    return _parseAuth(response);
  }

  @override
  Future<AuthResponseModel> loginWithEmail(String email, {String? name}) async {
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final data = <String, dynamic>{'email': email, 'deviceInfo': deviceInfo};
    if (name != null && name.isNotEmpty) data['name'] = name;

    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/login',
      data: data,
    );
    return _parseAuth(response);
  }

  @override
  Future<AuthResponseModel> verifyEmailOtp(String email, String otp) async {
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/email/verify',
      data: {'email': email, 'otp': otp, 'deviceInfo': deviceInfo},
    );
    return _parseAuth(response);
  }

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/google',
      data: {'idToken': idToken, 'deviceInfo': deviceInfo},
    );
    return _parseAuth(response);
  }

  @override
  Future<dynamic> completeProfile(Map<String, dynamic> profile) async {
    final response = await _serviceHelper.putHelper(
      target: '/v1/users/profile',
      token: 'provide',
      body: profile,
    );
    response.ensureSuccess();
    try {
      final json = jsonDecode((response as Success).data.toString());
      return json['data'];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    if (response is! Success) return null;
    try {
      final json = jsonDecode(response.data.toString());
      if (json['success'] == true && json['data'] != null) {
        return Map<String, dynamic>.from(json['data']);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> logout({dynamic fcmToken}) async {
    await _serviceHelper.postHelper(
      target: '/v1/auth/logout',
      token: 'provide',
      // Lets the server unlink push notifications from this phone only.
      data: {if (fcmToken is String) 'fcmToken': fcmToken},
    );
  }
}
