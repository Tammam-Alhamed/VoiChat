import 'session_user.dart';
import 'user_device.dart';

/// Everything the app needs to know about the current session: the user,
/// badge counters and the user's active devices.
class SessionData {
  SessionUser? user;
  bool isBlocked;
  String country;
  int unseen;
  int unReadMessages;
  List<UserDevice> userDevices;

  SessionData({
    this.user,
    required this.isBlocked,
    required this.country,
    required this.unseen,
    required this.unReadMessages,
    required this.userDevices,
  });
}
