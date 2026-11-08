import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shoeebapk/features/settings/state/account_setting_provider.dart';
import '../../core/helpers/store_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/network/socket_service.dart';
import '../../features/calls/state/calls_provider.dart';
import '../../features/chat/viewmodel/chat_viewmodel.dart';
import '../../features/follow/followings_followers_provider.dart';
import '../../features/home/tabs/messages/viewmodel/messages_tab_viewmodel.dart';
import '../../features/notification/notifications_provider.dart';
import '../../features/profile/state/target_profile_provider.dart';
import '../../features/settings/block/blocked_users_provider.dart';
import '../../features/settings/creators/manage_creators_provider.dart';
import '../../features/settings/state/call_rating_state_provider.dart';
import '../../features/settings/state/performance_state_provider.dart';
import '../../features/home/tabs/profile/viewmodel/profile_tab_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/session/session_manager.dart';
import '../../features/auth/auth_injection.dart';
import '../../features/home/home_injection.dart';
import '../../features/discover/discover_injection.dart';
import '../../features/followings/followings_injection.dart';
import '../../features/live/live_injection.dart';
import '../../features/recent_calls/recent_calls_injection.dart';
import '../../features/session/session_injection.dart';

/// Service locator for the data and domain layers (data sources,
/// repositories, use cases). Presentation controllers live in GetX.
final sl = GetIt.instance;

Future<void> init() async {
  await Future.wait([GetStorage.init()]);

  // External
  sl.registerLazySingleton(() => GetStorage());
  sl.registerLazySingleton(() => http.Client());
  // Core
  sl.registerLazySingleton(() => StoreHelper.withBox(sl<GetStorage>()));
  sl.registerLazySingleton(
    () => ServiceHelper(
      client: sl<http.Client>(),
      storeHelper: sl<StoreHelper>(),
    ),
  );

  // Socket (shared singleton across features)
  sl.registerLazySingleton(() => SocketService(storeHelper: sl<StoreHelper>()));

  // Features
  initSessionFeature();
  initAuthFeature();
  initHomeFeature();
  initDiscoverFeature();
  initFollowingsFeature();
  initLiveFeature();
  initRecentCallsFeature();

  // Providers
  _initializeProviders(sl);
  SessionManager.addResetHook(() {
    final BuildContext? ctx = Get.context;
    if (ctx != null) {
      Provider.of<MessagesTabViewModel>(ctx, listen: false).reset();
    }
  });
}

void _initializeProviders(GetIt sl) {
  // Calls Feature Provider
  // Calls Feature — singleton so notification handler can always reach it
  sl.registerLazySingleton(
    () => CallsProvider(
      serviceHelper: sl<ServiceHelper>(),
      storeHelper: sl<StoreHelper>(),
      socketService: sl<SocketService>(),
    ),
  );

  // Home feature — repository is injected into provider (dependency inversion)

  // Messages / Chat (MVVM)
  sl.registerLazySingleton(
    () => MessagesTabViewModel(
      serviceHelper: sl<ServiceHelper>(),
      storeHelper: sl<StoreHelper>(),
      socketService: sl<SocketService>(),
    ),
  );

  sl.registerFactory(
    () => ChatViewModel(
      serviceHelper: sl<ServiceHelper>(),
      storeHelper: sl<StoreHelper>(),
      socketService: sl<SocketService>(),
    ),
  );
  sl.registerFactory(
    () => BlockedUsersProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => TargetProfileProvider(serviceHelper: sl<ServiceHelper>()),
  );

  sl.registerLazySingleton(
    () => ProfileTabViewModel(
      serviceHelper: sl<ServiceHelper>(),
      storeHelper: sl<StoreHelper>(),
    ),
  );
  sl.registerFactory(
    () => PerformanceStateProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => CallRatingStateProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => ManageCreatorsProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => FollowingProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => AccountSettingProvider(serviceHelper: sl<ServiceHelper>()),
  );
  sl.registerFactory(
    () => NotificationsProvider(serviceHelper: sl<ServiceHelper>()),
  );
}
