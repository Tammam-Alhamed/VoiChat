import 'package:get/get.dart';

import '../../app/di/controller_registry.dart';
import '../../app/di/injection_container.dart';
import '../../core/session/session_manager.dart';
import '../../core/usecase/usecase.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/google_auth_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/complete_profile.dart';
import 'domain/usecases/login_with_email.dart';
import 'domain/usecases/login_with_google.dart';
import 'domain/usecases/logout.dart';
import 'domain/usecases/refresh_access_token.dart';
import 'domain/usecases/send_phone_otp.dart';
import 'domain/usecases/verify_email_otp.dart';
import 'domain/usecases/verify_phone_otp.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/auth_screen.dart';

/// Wires the authentication feature and plugs its logout and login-screen
/// steps into [SessionManager].
void initAuthFeature() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceHelper: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storeHelper: sl()),
  );
  sl.registerLazySingleton<GoogleAuthDataSource>(
    () => GoogleAuthDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl(), google: sl()),
  );

  sl.registerLazySingleton(() => SendPhoneOtp(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtp(sl()));
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => VerifyEmailOtp(sl()));
  sl.registerLazySingleton(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton(() => CompleteProfile(sl()));
  sl.registerLazySingleton(() => RefreshAccessToken(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  registerAppController(
    () => AuthController(
      sendPhoneOtp: sl(),
      verifyPhoneOtp: sl(),
      loginWithEmail: sl(),
      verifyEmailOtp: sl(),
      loginWithGoogle: sl(),
      completeProfile: sl(),
      refreshAccessToken: sl(),
    ),
  );

  SessionManager.configure(
    notifyServerLogout: () => sl<Logout>()(const NoParams()),
    openLogin: () => Get.offAll(() => const AuthScreen()),
  );
  SessionManager.addResetHook(
    () => ifControllerCreated<AuthController>((c) => c.resetFlow()),
  );
}
