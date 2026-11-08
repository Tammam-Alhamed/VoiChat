import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/error/result.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_status.dart';
import '../../domain/entities/session_data.dart';
import '../../domain/usecases/cache_session.dart';
import '../../domain/usecases/check_app_status.dart';
import '../../domain/usecases/get_cached_session.dart';
import '../../domain/usecases/get_stored_user_session.dart';
import '../../domain/usecases/has_stored_login.dart';
import '../../domain/usecases/sync_fcm_token.dart';
import '../widgets/access_denied_dialog.dart';

/// App-wide holder of the signed-in user's session. Screens read [session]
/// for the user, badge counters and devices; every local change is written
/// back to the on-device snapshot so the cache never goes stale.
class SessionController extends GetxController {
  final HasStoredLogin _hasStoredLogin;
  final CheckAppStatus _checkAppStatus;
  final SyncFcmToken _syncFcmToken;
  final GetCachedSession _getCachedSession;
  final GetStoredUserSession _getStoredUserSession;
  final CacheSession _cacheSession;

  SessionController({
    required HasStoredLogin hasStoredLogin,
    required CheckAppStatus checkAppStatus,
    required SyncFcmToken syncFcmToken,
    required GetCachedSession getCachedSession,
    required GetStoredUserSession getStoredUserSession,
    required CacheSession cacheSession,
  }) : _hasStoredLogin = hasStoredLogin,
       _checkAppStatus = checkAppStatus,
       _syncFcmToken = syncFcmToken,
       _getCachedSession = getCachedSession,
       _getStoredUserSession = getStoredUserSession,
       _cacheSession = cacheSession;

  SessionData? session;

  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  String _blockMessage = '';
  String get blockMessage => _blockMessage;

  /// Set right before [checkAppStatus] returns false for a dead token, so
  /// [verifySessionOrBlock] does not show the "Access Denied" dialog, which
  /// is reserved for banned accounts and devices.
  bool _sessionExpired = false;

  /// Whether a signed-in account is stored on this device.
  bool get hasStoredLogin => _hasStoredLogin(const NoParams());

  /// Forgets everything about the signed-in user (called on logout).
  /// Silent: the screens that read [session] are already gone by then.
  void reset() {
    session = null;
    _isBlocked = false;
    _blockMessage = '';
    _sessionExpired = false;
  }

  /// Loads the last-known snapshot from the device so Home can render
  /// immediately while the server is revalidated in the background.
  /// Returns true when [session] is populated.
  bool hydrateFromCache() {
    if (session != null) return true;
    final cached = _getCachedSession(const NoParams());
    if (cached == null) return false;
    session = cached;
    return true;
  }

  /// Last resort when there is no snapshot and the status check failed
  /// (for example offline on the first login): builds a minimal session
  /// from the user saved at login so screens that need [session] never
  /// crash. Counters start at zero and are corrected on the next sync.
  bool hydrateFromRawUserFallback() {
    if (session != null) return true;
    final stored = _getStoredUserSession(const NoParams());
    if (stored == null) return false;
    session = stored;
    return true;
  }

  void _fallbackToLocalData() {
    if (session != null) return;
    if (hydrateFromCache()) return;
    hydrateFromRawUserFallback();
  }

  void _persistSnapshot() {
    final current = session;
    if (current != null) _cacheSession(current);
  }

  /// Validates the session with the server. Returns false when the account
  /// is blocked or the session has expired; in every other case (including
  /// network errors) the UI may proceed, using local data if needed.
  Future<bool> checkAppStatus() async {
    final result = await _checkAppStatus(const NoParams());

    switch (result) {
      case Ok(data: AppStatusBlocked(:final reason)):
        _isBlocked = true;
        _blockMessage = reason;
        update();
        return false;

      case Ok(data: AppStatusSessionExpired()):
        _sessionExpired = true;
        // Not awaited: verifySessionOrBlock() must still see
        // _sessionExpired before the session reset clears it.
        unawaited(SessionManager.endSession(notifyServer: false));
        return false;

      case Ok(data: AppStatusActive(session: final fresh)):
        session = fresh;
        _persistSnapshot();
        update();
        return true;

      case Ok(data: AppStatusUnavailable()):
        _fallbackToLocalData();
        return true;

      case Err(:final failure):
        if (kDebugMode)
          debugPrint('SessionController.checkAppStatus: $failure');
        _fallbackToLocalData();
        return true;
    }
  }

  /// Runs [checkAppStatus] and shows the "Access Denied" dialog when the
  /// account turns out to be blocked. Returns true if the caller may
  /// proceed.
  Future<bool> verifySessionOrBlock() async {
    _sessionExpired = false;
    final allowed = await checkAppStatus();
    if (!allowed && !_sessionExpired) {
      Get.dialog(
        barrierDismissible: false,
        AccessDeniedDialog(message: _blockMessage),
      );
    }
    return allowed;
  }

  /// Revalidates the session after Home is already visible (cache-first
  /// launch) without blocking the UI.
  Future<void> refreshSessionInBackground() async {
    final allowed = await verifySessionOrBlock();
    if (!allowed) return;
    await syncFcmToken();
  }

  Future<void> syncFcmToken() async {
    await _syncFcmToken(const NoParams());
  }

  void updateUserData({String? name, String? bio, String? profileImage}) {
    final user = session?.user;
    if (user == null) return;
    if (name != null) user.name = name;
    if (bio != null) user.bio = bio;
    if (profileImage != null) user.profileImage = profileImage;
    _persistSnapshot();
    update();
  }

  void setUnSeenZero() {
    session!.unseen = 0;
    _persistSnapshot();
    update();
  }

  void setUnSeenMessagesZero() {
    session!.unReadMessages = 0;
    _persistSnapshot();
    update();
  }

  void updateBirthdate(DateTime birthdate, DateTime changedAt) {
    final user = session?.user;
    if (user == null) return;
    user.birthdate = birthdate;
    user.birthdateUpdatedAt = changedAt;
    _persistSnapshot();
    update();
  }

  /// Empty values are stored as null, since screens check `email != null`.
  void updateEmailOrPhone(String? email, String? phone) {
    session!.user!.email = (email == null || email.isEmpty) ? null : email;
    session!.user!.phone = (phone == null || phone.isEmpty) ? null : phone;
    _persistSnapshot();
    update();
  }

  void updateAgency(String? agency) {
    session!.user!.referredByProfileId = agency;
    _persistSnapshot();
    update();
  }
}
