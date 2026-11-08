import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/helpers/toast_helper.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../session/presentation/controllers/session_controller.dart';

/// Shared "the user is now authenticated" step used by every login and
/// sign-up path (Google, phone OTP, email OTP, new-account profile).
///
/// Loads this account's session (from the server, or the stored user when
/// offline) and goes straight to Home, without passing through the splash
/// screen.
Future<void> completeLoginAndGoHome(SessionController session) async {
  // Never reuse in-memory or cached data: it may belong to the previous
  // account.
  session.reset();
  final allowed = await session.verifySessionOrBlock();
  // The blocked dialog or the login screen has already been shown.
  if (!allowed) return;

  // Home reads the session everywhere; never open it without the user's
  // data (offline with nothing stored keeps the user here to retry).
  if (session.session?.user == null && !session.hydrateFromRawUserFallback()) {
    ToastHelper.showErrorToast(
      message: 'Could not load your account. Please try again.',
    );
    return;
  }

  Get.offAll(() => const HomeScreen());
  unawaited(session.syncFcmToken());
}
