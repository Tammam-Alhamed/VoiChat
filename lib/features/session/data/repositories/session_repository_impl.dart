import '../../../../core/error/result.dart';
import '../../../../core/services/fcm_token_service.dart';
import '../../domain/entities/app_status.dart';
import '../../domain/entities/session_data.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_data_source.dart';
import '../datasources/session_remote_data_source.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remote;
  final SessionLocalDataSource _local;

  SessionRepositoryImpl({
    required SessionRemoteDataSource remote,
    required SessionLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  @override
  bool hasStoredLogin() => _local.hasStoredLogin();

  @override
  Future<Result<AppStatus>> checkAppStatus() {
    return guardResult(_remote.checkStatus);
  }

  @override
  Future<Result<void>> syncFcmToken() {
    return guardResult(
      () => FcmService.syncToken(uploadToken: _remote.uploadFcmToken),
    );
  }

  @override
  SessionData? getCachedSession() => _local.readSnapshot();

  @override
  SessionData? getStoredUserSession() => _local.readStoredUserSession();

  @override
  void cacheSession(SessionData session) => _local.cacheSnapshot(session);
}
