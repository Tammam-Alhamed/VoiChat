import 'dart:async';

import 'package:get/get.dart';

import '../helpers/deep_link_service.dart';
import '../helpers/store_helper.dart';
import '../network/socket_service.dart';
import '../services/fcm_token_service.dart';
import '../../app/di/injection_container.dart';

/// The single place a user session ends: the logout button, an expired or
/// invalid token (401), or the server reporting the session is gone.
///
/// Everything tied to the signed-in user is cleared here so the next login
/// (same or another account) always starts clean:
///  - the server session (optional), the push token and the realtime socket
///  - stored session data (device preferences such as language and theme
///    are kept)
///  - in-memory state held by app-wide controllers
///
/// Core code must not depend on features, so the feature specific parts
/// (telling the server, opening the login screen, resetting controllers)
/// are plugged in at startup through [configure] and [addResetHook].
class SessionManager {
  SessionManager._();

  static bool _ending = false;

  static Future<void> Function()? _notifyServerLogout;
  static void Function()? _openLogin;
  static final List<void Function()> _resetHooks = [];

  /// Wires the feature specific steps of ending a session.
  static void configure({
    required Future<void> Function() notifyServerLogout,
    required void Function() openLogin,
  }) {
    _notifyServerLogout = notifyServerLogout;
    _openLogin = openLogin;
  }

  /// Registers a callback that clears one controller's in-memory state.
  static void addResetHook(void Function() hook) => _resetHooks.add(hook);

  static Future<void> endSession({bool notifyServer = true}) async {
    // Several requests can get a 401 at the same time; end only once.
    if (_ending) return;
    _ending = true;
    try {
      final store = sl<StoreHelper>();

      if (notifyServer) {
        try {
          await _notifyServerLogout?.call();
        } catch (_) {
          // Logout never waits on the network.
        }
      }

      // Stop realtime traffic for this account right away.
      final socket = sl<SocketService>();
      socket.offAll();
      socket.disconnect();
      FcmService.stopListening();
      DeepLinkService.instance.onHomeDisposed();

      await store.clearSession();

      _openLogin?.call();

      // Reset in-memory state once the old screens are gone, silently, so
      // nothing that is still animating out gets rebuilt.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _resetControllers();
    } finally {
      _ending = false;
    }
  }

  static void _resetControllers() {
    if (Get.context == null) return;
    for (final hook in _resetHooks) {
      try {
        hook();
      } catch (_) {
        // A controller that was never created has nothing to reset.
      }
    }
  }
}
