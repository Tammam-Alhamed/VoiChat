import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import 'data/datasources/recent_calls_remote_data_source.dart';
import 'data/repositories/recent_calls_repository_impl.dart';
import 'domain/repositories/recent_calls_repository.dart';
import 'domain/usecases/delete_call_history.dart';
import 'domain/usecases/get_call_history.dart';
import 'presentation/controllers/recent_calls_controller.dart';

/// Wires the Recent Calls tab feature.
void initRecentCallsFeature() {
  sl.registerLazySingleton<RecentCallsRemoteDataSource>(
    () => RecentCallsRemoteDataSourceImpl(serviceHelper: sl()),
  );
  sl.registerLazySingleton<RecentCallsRepository>(
    () => RecentCallsRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => GetCallHistory(sl()));
  sl.registerLazySingleton(() => DeleteCallHistory(sl()));

  registerAppController(
    () => RecentCallsController(getCallHistory: sl(), deleteCallHistory: sl()),
  );
}
