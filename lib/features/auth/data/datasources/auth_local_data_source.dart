import 'dart:convert';

import '../../../../core/helpers/store_helper.dart';

/// Tokens and the signed-in user stored on the device.
abstract class AuthLocalDataSource {
  dynamic getRefreshToken();

  dynamic getFcmToken();

  /// Stores a freshly issued session. The login flag is set only for
  /// existing accounts; new accounts must finish their profile first.
  void saveSession({
    required String accessToken,
    String? refreshToken,
    dynamic deviceId,
    dynamic user,
    required bool markLoggedIn,
  });

  void saveTokens({String? accessToken, String? refreshToken});

  void saveUser(dynamic user);

  void setLoggedIn(bool value);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StoreHelper _storeHelper;

  AuthLocalDataSourceImpl({required StoreHelper storeHelper})
    : _storeHelper = storeHelper;

  @override
  dynamic getRefreshToken() => _storeHelper.readSomething('refresh_token');

  @override
  dynamic getFcmToken() => _storeHelper.readSomething('fcm_token');

  @override
  void saveSession({
    required String accessToken,
    String? refreshToken,
    dynamic deviceId,
    dynamic user,
    required bool markLoggedIn,
  }) {
    _storeHelper.setAccessToken(accessToken);
    if (refreshToken != null) {
      _storeHelper.storeSomeThing('refresh_token', refreshToken);
    }
    // Server-side id of this device's session.
    if (deviceId != null) _storeHelper.storeSomeThing('device_id', deviceId);
    if (user != null) saveUser(user);
    if (markLoggedIn) _storeHelper.setLogin(true);
  }

  @override
  void saveTokens({String? accessToken, String? refreshToken}) {
    if (accessToken != null) _storeHelper.setAccessToken(accessToken);
    if (refreshToken != null) {
      _storeHelper.storeSomeThing('refresh_token', refreshToken);
    }
  }

  @override
  void saveUser(dynamic user) {
    _storeHelper.storeSomeThing('user', jsonEncode(user));
  }

  @override
  void setLoggedIn(bool value) => _storeHelper.setLogin(value);
}
