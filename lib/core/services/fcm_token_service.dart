import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';

/// Keeps the Firebase push token registered on the server for the
/// signed-in account: uploads it once per change and re-uploads whenever
/// Firebase rotates it.
class FcmService {
  static final GetStorage _box = GetStorage();
  static const String _tokenKey = 'fcm_token';

  static StreamSubscription<String>? _subscription;

  /// Uploads the current token if it differs from the last uploaded one,
  /// then starts listening for refreshes.
  static Future<void> syncToken({
    required Future<bool> Function(String token) uploadToken,
  }) async {
    final currentToken = await FirebaseMessaging.instance.getToken();

    if (currentToken == null || currentToken.isEmpty) return;

    final savedToken = _box.read<String>(_tokenKey);

    if (savedToken == currentToken) return;

    final success = await uploadToken(currentToken);

    if (success) {
      await _box.write(_tokenKey, currentToken);
      listenTokenRefresh(uploadToken: uploadToken);
    }
  }

  /// Logout: stop uploading refreshed tokens for the old account.
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void listenTokenRefresh({
    required Future<bool> Function(String token) uploadToken,
  }) {
    // Replace any previous listener so only one upload runs per refresh.
    _subscription?.cancel();

    _subscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      try {
        final success = await uploadToken(newToken);

        if (success) {
          await _box.write(_tokenKey, newToken);
        }
      } catch (_) {}
    });
  }
}
