import '../../../../core/error/result.dart';
import '../entities/app_status.dart';
import '../entities/session_data.dart';

/// Contract for reading, validating and caching the current session.
abstract class SessionRepository {
  bool hasStoredLogin();

  Future<Result<AppStatus>> checkAppStatus();

  /// Makes sure the server knows this device's current push token.
  Future<Result<void>> syncFcmToken();

  SessionData? getCachedSession();

  SessionData? getStoredUserSession();

  void cacheSession(SessionData session);
}
