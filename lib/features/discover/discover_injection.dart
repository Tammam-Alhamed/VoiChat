import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import 'data/datasources/discover_remote_data_source.dart';
import 'data/repositories/discover_repository_impl.dart';
import 'domain/repositories/discover_repository.dart';
import 'domain/usecases/get_clients.dart';
import 'domain/usecases/get_country_online_counts.dart';
import 'presentation/controllers/discover_controller.dart';

/// Wires the Home tab (user discovery) feature.
void initDiscoverFeature() {
  sl.registerLazySingleton<DiscoverRemoteDataSource>(
    () => DiscoverRemoteDataSourceImpl(serviceHelper: sl()),
  );
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => GetClients(sl()));
  sl.registerLazySingleton(() => GetCountryOnlineCounts(sl()));

  registerAppController(() => DiscoverController(getClients: sl()));
}
