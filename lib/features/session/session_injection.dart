import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import '../../core/session/session_manager.dart';
import 'data/datasources/session_local_data_source.dart';
import 'data/datasources/session_remote_data_source.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/cache_session.dart';
import 'domain/usecases/check_app_status.dart';
import 'domain/usecases/get_cached_session.dart';
import 'domain/usecases/get_stored_user_session.dart';
import 'domain/usecases/has_stored_login.dart';
import 'domain/usecases/sync_fcm_token.dart';
import 'presentation/controllers/session_controller.dart';

/// Wires the session feature: data sources, repository, use cases and the
/// app-wide [SessionController].
void initSessionFeature() {
  sl.registerLazySingleton<SessionRemoteDataSource>(
    () => SessionRemoteDataSourceImpl(serviceHelper: sl(), storeHelper: sl()),
  );
  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(storeHelper: sl()),
  );
  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(remote: sl(), local: sl()),
  );

  sl.registerLazySingleton(() => HasStoredLogin(sl()));
  sl.registerLazySingleton(() => CheckAppStatus(sl()));
  sl.registerLazySingleton(() => SyncFcmToken(sl()));
  sl.registerLazySingleton(() => GetCachedSession(sl()));
  sl.registerLazySingleton(() => GetStoredUserSession(sl()));
  sl.registerLazySingleton(() => CacheSession(sl()));

  registerAppController(
    () => SessionController(
      hasStoredLogin: sl(),
      checkAppStatus: sl(),
      syncFcmToken: sl(),
      getCachedSession: sl(),
      getStoredUserSession: sl(),
      cacheSession: sl(),
    ),
  );

  SessionManager.addResetHook(
    () => ifControllerCreated<SessionController>((c) => c.reset()),
  );
}
