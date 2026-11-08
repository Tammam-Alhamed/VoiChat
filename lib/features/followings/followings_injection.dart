import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import 'data/datasources/followings_remote_data_source.dart';
import 'data/repositories/followings_repository_impl.dart';
import 'domain/repositories/followings_repository.dart';
import 'domain/usecases/get_followings.dart';
import 'presentation/controllers/followings_controller.dart';

/// Wires the Follow tab feature.
void initFollowingsFeature() {
  sl.registerLazySingleton<FollowingsRemoteDataSource>(
    () => FollowingsRemoteDataSourceImpl(serviceHelper: sl()),
  );
  sl.registerLazySingleton<FollowingsRepository>(
    () => FollowingsRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton(() => GetFollowings(sl()));

  registerAppController(() => FollowingsController(getFollowings: sl()));
}
