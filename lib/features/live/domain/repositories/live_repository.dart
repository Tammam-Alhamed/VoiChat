import '../../../../core/error/result.dart';
import '../entities/live_session_access.dart';

/// Contract for entering, starting and ending live rooms.
abstract class LiveRepository {
  Future<Result<LiveSessionAccess>> joinLive(String liveId);

  Future<Result<LiveSessionAccess>> startLive({
    required String title,
    int? goalAmount,
  });

  /// The host's own session that is still running on the server (the app
  /// was killed or lost connection), or null.
  Future<Result<LiveSessionAccess?>> getActiveLive();

  Future<Result<void>> endLive();
}
