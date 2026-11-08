import 'session_data.dart';

/// What the server answered when asked whether this device and token may
/// use the app.
sealed class AppStatus {
  const AppStatus();
}

/// The account or device is banned. [reason] is shown to the user.
final class AppStatusBlocked extends AppStatus {
  final String reason;
  const AppStatusBlocked(this.reason);
}

/// The request was accepted but the token no longer maps to a user
/// (expired, invalid or issued before a key rotation).
final class AppStatusSessionExpired extends AppStatus {
  const AppStatusSessionExpired();
}

/// The session is valid; [session] holds fresh data for it.
final class AppStatusActive extends AppStatus {
  final SessionData session;
  const AppStatusActive(this.session);
}

/// The server was reachable but the answer could not be used.
final class AppStatusUnavailable extends AppStatus {
  const AppStatusUnavailable();
}
