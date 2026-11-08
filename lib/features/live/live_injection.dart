import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import 'data/datasources/live_remote_data_source.dart';
import 'data/repositories/live_repository_impl.dart';
import 'domain/repositories/live_repository.dart';
import 'domain/usecases/end_live.dart';
import 'domain/usecases/get_active_live.dart';
import 'domain/usecases/join_live.dart';
import 'domain/usecases/start_live.dart';
import 'presentation/controllers/live_entry_controller.dart';

/// Wires the live feature.
void initLiveFeature() {
  sl.registerLazySingleton<LiveRemoteDataSource>(
    () => LiveRemoteDataSourceImpl(serviceHelper: sl()),
  );
  sl.registerLazySingleton<LiveRepository>(
    () => LiveRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => JoinLive(sl()));
  sl.registerLazySingleton(() => StartLive(sl()));
  sl.registerLazySingleton(() => GetActiveLive(sl()));
  sl.registerLazySingleton(() => EndLive(sl()));

  registerAppController(
    () => LiveEntryController(
      joinLive: sl(),
      startLive: sl(),
      getActiveLive: sl(),
      endLive: sl(),
    ),
  );
}
