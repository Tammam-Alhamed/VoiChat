import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/di/injection_container.dart';
import '../../features/calls/state/calls_provider.dart';

/// Notification channel IDs and action IDs — must match AndroidManifest &
/// backend FCM data payload keys.
class _NC {
  // Channels
  static const String callChannelId = 'call_channel';
  static const String callChannelName = 'Incoming Calls';
  static const String chatChannelId = 'high_importance_channel';
  static const String chatChannelName = 'High Importance Notifications';

  // Android notification action IDs (for call notification buttons)
  static const String actionAccept = 'ACCEPT_CALL';
  static const String actionDecline = 'DECLINE_CALL';

  // Notification IDs
  static const int callNotificationId = 1000;
}

/// Manages Firebase Cloud Messaging (FCM) + Flutter Local Notifications.
///
/// Covers all three app states:
///  • Foreground  — show heads-up notification OR route call directly
///  • Background  — notification shown by FCM; action buttons handled here
///  • Terminated  — notification shown by FCM; tap / action handled on launch
///
/// Call notifications include two action buttons:
///  ✅ Accept (green)   — answers the call and opens InCallScreen
///  ❌ Decline (red)    — declines the call silently
///
/// When the caller cancels before the receiver answers:
///  • The call screen (if open) is dismissed via [CallsProvider]
///  • The notification is cancelled automatically via [cancelCallNotification]
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialize ───────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    // ── Android channels ────────────────────────────────────────────────────
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Full-screen / call channel (highest priority, shows over lock screen)
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _NC.callChannelId,
        _NC.callChannelName,
        description: 'Incoming call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF8B3EE8),
        showBadge: true,
      ),
    );

    // Regular chat / alert channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _NC.chatChannelId,
        _NC.chatChannelName,
        description: 'Chat and general notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('noti'),
        showBadge: true,
      ),
    );

    // ── Initialization settings ─────────────────────────────────────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      // Tap on notification body
      onDidReceiveNotificationResponse: (NotificationResponse res) {
        _handleActionOrTap(res.payload, res.actionId);
      },
      // Background action button taps (Android 12+ on background isolate)
      onDidReceiveBackgroundNotificationResponse: _backgroundActionHandler,
    );

    // ── FCM permission ──────────────────────────────────────────────────────
    // NOT requested here on purpose — this runs at app startup, before the
    // person has even logged in, which used to pop the system permission
    // dialog on top of the splash/auth screens. The actual request now
    // happens from HomeScreen.initState() (requestNotificationPermission())
    // once they're logged in and looking at the app itself. Everything
    // else below (channels, listeners, local-notifications plugin) still
    // has to be set up eagerly so the app can receive/display pushes even
    // before Home is reached.

    // iOS foreground options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false, // We show our own heads-up
          badge: true,
          sound: false,
        );

    if (kDebugMode) {
      final token = await FirebaseMessaging.instance.getToken();
      print('NotificationHelper: FCM token = $token');
    }

    // ── FCM listeners ───────────────────────────────────────────────────────

    // 1. App in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (kDebugMode) print('NotificationHelper [FG]: ${msg.data}');
      _processMessage(msg, isForeground: true);
    });

    // 2. App in BACKGROUND — user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (kDebugMode) print('NotificationHelper [BG tap]: ${msg.data}');
      _processMessage(msg, isForeground: false, clicked: true);
    });

    // 3. App TERMINATED — user tapped notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      if (kDebugMode)
        print('NotificationHelper [TERMINATED tap]: ${initial.data}');
      _processMessage(initial, isForeground: false, clicked: true);
    }
  }

  // ── Process FCM message ───────────────────────────────────────────────────
  /*
  static void _processMessage(
    RemoteMessage message, {
    required bool isForeground,
    bool clicked = false,
  }) {
    final data = message.data;
    final type = data['type']?.toString() ?? '';

    if (type == 'call') {
      final callData = _extractCallData(data);

      if (isForeground) {
        // App is open → route directly (show our full-screen call UI)
        _routeIncomingCall(callData);
        // Also show a heads-up notification so user can accept/decline
        // even if the app is in a different screen
        _showCallNotification(callData);
      } else if (clicked) {
        // User tapped the notification body → open call screen
        _routeIncomingCall(callData);
      }
      // Background / terminated with no click → notification is already shown
      // by FCM system; action buttons are handled by _backgroundActionHandler
    } else {
      // Regular chat / alert notification
      if (isForeground) {
        _showChatNotification(
          title: message.notification?.title ?? 'Voichat',
          body: message.notification?.body ?? '',
          payload: jsonEncode(data),
        );
      }
    }
  }
*/
  static void _processMessage(
    RemoteMessage message, {
    required bool isForeground,
    bool clicked = false,
  }) {
    final data = message.data;
    final type = data['type']?.toString() ?? '';

    if (type == 'call') {
      final callData = _extractCallData(data);

      if (isForeground) {
        // التطبيق مفتوح → بس وجّه لشاشة الرنين. ما تبني ولا إشعار نظام.
        _routeIncomingCall(callData);
      } else if (clicked) {
        // المستخدم ضغط على الإشعار (من الخلفية أو من terminated) → افتح شاشة الرنين
        _routeIncomingCall(callData);
      }
      // إذا مو foreground ومو clicked (يعني التطبيق بالخلفية/مقفول ولسا ما ضغط):
      // الإشعار أصلاً مبني من firebaseMessagingBackgroundHandler، ما في داعي نعمل شي هون.
    } else if (type == 'call_cancel') {
      _plugin.cancel(
        _NC.callNotificationId,
      ); // ألغي إشعار المكالمة فوراً بأي حالة
    } else {
      if (isForeground) {
        _showChatNotification(
          title: message.notification?.title ?? 'Voichat',
          body: message.notification?.body ?? '',
          payload: jsonEncode(data),
        );
      }
    }
  }
  // ── Route incoming call to CallsProvider ──────────────────────────────────

  static void _routeIncomingCall(Map<String, dynamic> callData) {
    try {
      final provider = sl<CallsProvider>();
      provider.handleIncomingCall(callData);
    } catch (e) {
      if (kDebugMode) print('NotificationHelper: routing error: $e');
    }
  }

  // ── Show call heads-up notification with Accept / Decline buttons ─────────

  static Future<void> _showCallNotification(
    Map<String, dynamic> callData,
  ) async {
    final callerName = callData['callerName'] ?? 'Unknown';
    final callType = callData['callType'] ?? 'video';
    final payload = jsonEncode(callData);

    final androidDetails = AndroidNotificationDetails(
      _NC.callChannelId,
      _NC.callChannelName,
      channelDescription: 'Incoming call notifications',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true, // Show over lock screen / other apps
      ongoing: true, // Cannot be dismissed by swipe
      autoCancel: false,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('ringtone'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 300, 500]),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF8B3EE8),
      ledColor: const Color(0xFF8B3EE8),
      ledOnMs: 500,
      ledOffMs: 500,

      // ⚠️ إضافة هاد الخيار المهم لمنع نزول الإشعار للسلة
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      usesChronometer: true, // بيخلي عداد الوقت يظهر
      // ⚠️ الإعدادات المهمة لمنع اختفاء الإشعار
      visibility: NotificationVisibility.public,
      timeoutAfter: null, // أو 0 - لمنع timeout
      // ⚠️ إعدادات إضافية للإبقاء على الإشعار ظاهر
      additionalFlags: Int32List.fromList(<int>[
        4, // FLAG_NO_CLEAR
        32, // FLAG_ONGOING_EVENT (إذا ongoing ما اشتغل)
      ]),

      // Action buttons shown below the notification
      actions: [
        // Decline — red via icon name (icon must be in drawable: ic_call_end)
        const AndroidNotificationAction(
          _NC.actionDecline,
          'Decline',
          icon: DrawableResourceAndroidBitmap('ic_call_end'),
          cancelNotification: true,
          showsUserInterface: false, // background action
        ),
        // Accept — green (icon must be in drawable: ic_call)
        AndroidNotificationAction(
          _NC.actionAccept,
          callType == 'video' ? 'Accept Video' : 'Accept',
          icon: const DrawableResourceAndroidBitmap('ic_call'),
          cancelNotification: true,
          showsUserInterface: true, // brings app to foreground
        ),
      ],
    );

    await _plugin.show(
      _NC.callNotificationId,
      callType == 'video' ? 'Incoming Video Call' : 'Incoming Call',
      callerName,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ── Cancel the call notification (when caller cancels) ───────────────────

  /// Call this from [CallsProvider] when the caller cancels the call
  /// so the notification is dismissed on the receiver's device.
  static Future<void> cancelCallNotification() async {
    await _plugin.cancel(_NC.callNotificationId);
  }

  // ── Show regular chat notification ────────────────────────────────────────

  static Future<void> _showChatNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _NC.chatChannelId,
      _NC.chatChannelName,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ── Handle tap or action on a notification ────────────────────────────────

  static void _handleActionOrTap(String? payload, String? actionId) {
    if (payload == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload);
    } catch (_) {
      return;
    }

    if (data['type'] != 'call' && data['callId'] == null) return;

    final callData = data.containsKey('callId') ? data : _extractCallData(data);

    if (actionId == _NC.actionAccept) {
      // User tapped "Accept" action button
      _routeIncomingCall(callData);
      // After routing, immediately answer
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          sl<CallsProvider>().answerCall();
        } catch (_) {}
      });
    } else if (actionId == _NC.actionDecline) {
      // User tapped "Decline" action button — decline in background
      _declineInBackground(callData['callId']?.toString());
    } else {
      // Plain tap — open call screen
      _routeIncomingCall(callData);
    }
  }

  static void _declineInBackground(String? callId) {
    if (callId == null) return;
    try {
      sl<CallsProvider>().declineCall();
    } catch (e) {
      if (kDebugMode) print('NotificationHelper: decline bg error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _extractCallData(Map<String, dynamic> data) {
    return {
      'callId': data['callId'],
      'callType': data['callType'] ?? 'video',
      'roomName': data['roomName'],
      'callerName': data['callerName'] ?? 'Incoming Call',
      'callerImage': data['callerImage'] ?? '',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level background action handler (required by flutter_local_notifications)
// This runs in a background isolate — only use GetIt / sl for stateless ops.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _backgroundActionHandler(NotificationResponse res) {
  // Re-initialize Firebase if needed (background isolate)
  // For action buttons in background, we rely on FCM + REST to decline.
  if (kDebugMode) {
    print('BG action: id=${res.actionId}, payload=${res.payload}');
  }

  if (res.payload == null) return;
  try {
    final data = jsonDecode(res.payload!);
    if (res.actionId == _NC.actionDecline) {
      // Best effort: decline via provider if app process still alive
      try {
        sl<CallsProvider>().declineCall();
      } catch (_) {}
    } else if (res.actionId == _NC.actionAccept) {
      // App will be brought to foreground via showsUserInterface: true
      // onDidReceiveNotificationResponse will handle the rest
    }
  } catch (_) {}
}

/// Global top-level FCM background handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('FCM BG handler: ${message.data}');
  }

  // For call notifications in background/terminated state:
  // FCM will show the notification automatically (from the FCM payload).
  // Action buttons are handled when user taps them via _backgroundActionHandler.
  //
  // We show a local notification here to ensure action buttons appear:
  final data = message.data;
  if (data['type'] == 'call') {
    // Re-init plugin in background isolate
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveBackgroundNotificationResponse: _backgroundActionHandler,
    );

    final callData = {
      'callId': data['callId'],
      'callType': data['callType'] ?? 'video',
      'roomName': data['roomName'],
      'callerName': data['callerName'] ?? 'Incoming Call',
      'callerImage': data['callerImage'] ?? '',
      'type': 'call',
    };

    final payload = jsonEncode(callData);
    final callerName = callData['callerName'] ?? 'Unknown';
    final callType = callData['callType'] ?? 'video';

    final androidDetails = AndroidNotificationDetails(
      _NC.callChannelId,
      _NC.callChannelName,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('ringtone'),
      enableVibration: true,
      actions: [
        const AndroidNotificationAction(
          _NC.actionDecline,
          'Decline',
          icon: DrawableResourceAndroidBitmap('ic_call_end'),
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _NC.actionAccept,
          callType == 'video' ? 'Accept Video' : 'Accept',
          icon: const DrawableResourceAndroidBitmap('ic_call'),
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    await plugin.show(
      _NC.callNotificationId,
      callType == 'video' ? 'Incoming Video Call' : 'Incoming Call',
      callerName,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  } else if (data['type'] == 'call_cancel') {
    // ← هون بالضبط، مكان الإضافة
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await plugin.cancel(_NC.callNotificationId);
  }
}
