import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../features/profile/profile_screen.dart';
import '../../app/di/injection_container.dart';
import '../constants.dart';
import '../network/service_helper.dart';
import '../utils/api_status.dart';
import 'store_helper.dart';
import 'toast_helper.dart';

import '../../features/session/presentation/controllers/session_controller.dart';

/// Opens the app on a user's profile when a shared profile link is tapped,
/// e.g. https://api.voichat.live/u/12345678 sent on WhatsApp.
///
/// Links can arrive before the user is logged in / before the home screen
/// exists (cold start). They're kept as "pending" and opened once
/// HomeScreen calls [onHomeReady].
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  String? _pendingProfileId;
  bool _homeReady = false;

  // app_links can deliver the same initial link twice on some devices.
  String? _lastHandledLink;
  DateTime _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Call once at startup (main.dart). The stream also delivers the link
  /// that launched the app.
  void init() {
    _sub ??= _appLinks.uriLinkStream.listen(
      _onLink,
      onError: (Object e) {
        if (kDebugMode) print('DeepLinkService error: $e');
      },
    );
  }

  /// Returns the profile id from https://<share host>/u/<profileId>.
  static String? profileIdFromUri(Uri uri) {
    if (uri.scheme != 'https' || uri.host != Constants.shareHost) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'u') return null;
    final id = segments[1];
    return RegExp(r'^[A-Za-z0-9_-]{1,32}$').hasMatch(id) ? id : null;
  }

  void _onLink(Uri uri) {
    final now = DateTime.now();
    final link = uri.toString();
    if (link == _lastHandledLink &&
        now.difference(_lastHandledAt) < const Duration(seconds: 3)) {
      return;
    }
    _lastHandledLink = link;
    _lastHandledAt = now;

    final profileId = profileIdFromUri(uri);
    if (profileId == null) return;
    _pendingProfileId = profileId;
    _openPending();
  }

  /// HomeScreen is up (user logged in): safe to navigate now.
  void onHomeReady() {
    _homeReady = true;
    _openPending();
  }

  void onHomeDisposed() => _homeReady = false;

  Future<void> _openPending() async {
    if (!_homeReady) return;
    final profileId = _pendingProfileId;
    if (profileId == null) return;
    _pendingProfileId = null;

    final ctx = Get.context;
    final myProfileId = ctx == null
        ? null
        : Get.find<SessionController>().session?.user?.profileId;
    if (myProfileId != null && myProfileId == profileId) {
      ToastHelper.showInfoToast(message: 'This is your own profile link');
      return;
    }

    final response = await sl<ServiceHelper>().getHelper(
      target:
          '/v1/users/search/profile-id?profileId=${Uri.encodeComponent(profileId)}',
      token: sl<StoreHelper>().getAccessToken(),
    );

    Map<String, dynamic>? user;
    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          user = body['data'] as Map<String, dynamic>;
        }
      } catch (e) {
        if (kDebugMode) print('DeepLinkService parse error: $e');
      }
    }

    if (user == null || user['id'] == null) {
      ToastHelper.showErrorToast(message: 'This profile is not available');
      return;
    }

    Get.to(
      () => TargetProfileScreen(
        userId: user!['id'].toString(),
        userName: user['name']?.toString() ?? '',
        userImage: user['profile_image']?.toString() ?? '',
        index: 0,
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
