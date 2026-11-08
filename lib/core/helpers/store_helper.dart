import 'package:get_storage/get_storage.dart';

class StoreHelper {
  final GetStorage box;

  StoreHelper.withBox(this.box);

  String getAccessToken() {
    return box.read('token') ?? 'token';
  }

  void setAccessToken(String token) {
    box.write('token', token);
  }

  void storeSomeThing(String key, dynamic value) {
    box.write(key, value);
  }

  dynamic readSomething(String key) {
    return box.read(key);
  }

  void setLogin(bool login) {
    box.write('is_login', login);
  }

  bool getIsLogin() {
    return box.read('is_login') ?? false;
  }

  // ─────────────────────────────────────────────────────────────
  // Local snapshot cache (splash/session data) — lets the app render
  // the Home screen instantly from the last-known state while a fresh
  // copy is fetched from the server in the background. Automatically
  // wiped on logout via destroy() (box.erase()).
  // ─────────────────────────────────────────────────────────────

  static const String _splashSnapshotKey = 'splash_snapshot';

  void cacheSplashSnapshot(Map<String, dynamic> json) {
    box.write(_splashSnapshotKey, json);
  }

  Map<String, dynamic>? readSplashSnapshot() {
    final raw = box.read(_splashSnapshotKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  void clearSplashSnapshot() {
    box.remove(_splashSnapshotKey);
  }

  // Everything tied to the signed-in account. Device preferences (language,
  // theme, notification sound/vibration) are NOT in this list on purpose, so
  // they survive logout.
  static const List<String> _sessionKeys = [
    'token',
    'refresh_token',
    'device_id',
    'user',
    'is_login',
    _splashSnapshotKey,
    // Cached "already uploaded" push token — must go so the next account
    // that signs in on this device registers it for itself.
    'fcm_token',
  ];

  /// Clears the signed-in session (use SessionManager.endSession, which also
  /// resets sockets and in-memory state).
  Future<void> clearSession() async {
    for (final key in _sessionKeys) {
      await box.remove(key);
    }
  }

  /// Wipes ALL local data, preferences included. Prefer [clearSession].
  Future<void> destroy() {
    return box.erase();
  }

  // ─────────────────────────────────────────────────────────────
  // Notification preferences — device-local only (no backend concept
  // of "sound"/"vibration" settings), read synchronously wherever a
  // local notification is about to be shown so the toggle actually has
  // a real effect instead of just being cosmetic UI state.
  // ─────────────────────────────────────────────────────────────

  static const String _inAppSoundKey = 'notif_in_app_sound';
  static const String _vibrationsKey = 'notif_vibrations';

  bool getInAppSoundEnabled() => box.read(_inAppSoundKey) ?? true;

  void setInAppSoundEnabled(bool enabled) {
    box.write(_inAppSoundKey, enabled);
  }

  bool getVibrationsEnabled() => box.read(_vibrationsKey) ?? false;

  void setVibrationsEnabled(bool enabled) {
    box.write(_vibrationsKey, enabled);
  }
}
