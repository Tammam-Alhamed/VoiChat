import 'dart:convert';

import '../../../../core/helpers/store_helper.dart';
import '../../domain/entities/session_data.dart';
import '../models/session_data_model.dart';
import '../models/session_user_model.dart';

/// On-device copy of the session, used to render Home instantly while the
/// server is revalidated in the background.
abstract class SessionLocalDataSource {
  /// Whether a signed-in account is stored on this device.
  bool hasStoredLogin();

  /// The last session snapshot, or null when none is stored or it can't be
  /// read.
  SessionData? readSnapshot();

  /// A minimal session built from the raw user object saved at login. Used
  /// only when no snapshot exists and the server can't be reached.
  SessionData? readStoredUserSession();

  void cacheSnapshot(SessionData session);
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final StoreHelper _storeHelper;

  SessionLocalDataSourceImpl({required StoreHelper storeHelper})
    : _storeHelper = storeHelper;

  @override
  bool hasStoredLogin() {
    return _storeHelper.getIsLogin() &&
        _storeHelper.getAccessToken() != 'token';
  }

  @override
  SessionData? readSnapshot() {
    final cached = _storeHelper.readSplashSnapshot();
    if (cached == null) return null;
    try {
      return SessionDataModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  @override
  SessionData? readStoredUserSession() {
    final raw = _storeHelper.readSomething('user');
    if (raw == null) return null;
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return SessionData(
        user: SessionUserModel.fromJson(Map<String, dynamic>.from(decoded)),
        isBlocked: false,
        country: '',
        unseen: 0,
        unReadMessages: 0,
        userDevices: const [],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void cacheSnapshot(SessionData session) {
    _storeHelper.cacheSplashSnapshot(session.toJson());
  }
}
