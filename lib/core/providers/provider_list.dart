import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../features/follow/followings_followers_provider.dart';
import '../../features/home/tabs/messages/viewmodel/messages_tab_viewmodel.dart';
import '../../features/home/tabs/profile/viewmodel/profile_tab_viewmodel.dart';
import '../../features/notification/notifications_provider.dart';
import '../../features/profile/state/target_profile_provider.dart';
import '../../features/settings/block/blocked_users_provider.dart';
import '../../features/settings/creators/manage_creators_provider.dart';
import '../../features/settings/state/account_setting_provider.dart'
    show AccountSettingProvider;
import '../../features/settings/state/call_rating_state_provider.dart';
import '../../features/settings/state/performance_state_provider.dart';
import '../../app/di/injection_container.dart' as di;
import '../../features/calls/state/calls_provider.dart';

class ProviderManager {
  static List<SingleChildWidget> getProviderList() {
    return [
      ChangeNotifierProvider(create: (_) => di.sl<MessagesTabViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<ProfileTabViewModel>()),
      ChangeNotifierProvider(create: (_) => di.sl<CallsProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<TargetProfileProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<BlockedUsersProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<PerformanceStateProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<CallRatingStateProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<ManageCreatorsProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<FollowingProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<AccountSettingProvider>()),
      ChangeNotifierProvider(create: (_) => di.sl<NotificationsProvider>()),
    ];
  }
}
