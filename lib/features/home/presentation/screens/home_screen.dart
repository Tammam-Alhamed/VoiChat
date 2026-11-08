import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/features/home/tabs/messages/viewmodel/messages_tab_viewmodel.dart';
import '../../../../core/themes/app_dark_colors.dart';
import '../controllers/navigation_controller.dart';
import '../../../discover/presentation/screens/home_tab.dart';
import '../../../followings/presentation/screens/follow_tab.dart';
import '../../tabs/messages/ui/messages_tab.dart';
import '../../tabs/profile/ui/profile_tab.dart';
import '../../../recent_calls/presentation/screens/recent_calls_tab.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/helpers/deep_link_service.dart';

import '../../../session/presentation/controllers/session_controller.dart';
import '../../../discover/presentation/controllers/discover_controller.dart';
import '../../../live/presentation/controllers/live_entry_controller.dart';
import '../../../../core/data/models/client_user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;

  // Bottom-nav tabs load on demand: a tab's real widget (and its data
  // fetch) is only constructed the first time the user actually opens it.
  // "Home" is visible by default, so it starts pre-loaded.
  final Set<int> _visitedTabs = {0};

  void _markVisited(int index) {
    if (_visitedTabs.add(index) && mounted) setState(() {});
  }

  late final NavigationController _navProvider;

  @override
  void initState() {
    super.initState();
    // A new HomeScreen (app start / fresh login) always opens on Home. The
    // provider is app-wide, so without this it kept the last tab (e.g.
    // Profile, where logout lives) while the page showed Home → each tab
    // hides itself when it isn't the selected one → blank white screen.
    _navProvider = Get.find<NavigationController>();
    _navProvider.reset();
    _navProvider.addListener(_syncPageWithNav);
    _pageController = PageController();
    _requestMicPermission();
    sl<SocketService>().connect();
    offListeners();
    setuplisteners();

    requestNotificationPermission();

    // Open a profile link that launched the app / arrived before login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.onHomeReady();
      // Back after a crash / force-close while live? Offer to resume it.
      if (mounted) Get.find<LiveEntryController>().offerResumeIfLive();
    });
  }

  Future<void> _requestMicPermission() async {
    final audioRecorder = AudioRecorder();
    await audioRecorder.hasPermission();
  }

  /// Keeps the visible page and the selected tab the same even when the tab
  /// is changed from elsewhere (e.g. the live room's Chat button).
  void _syncPageWithNav() {
    if (!mounted || !_pageController.hasClients) return;
    final index = _navProvider.currentIndex;
    if (_pageController.page?.round() == index) return;
    _markVisited(index);
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _navProvider.removeListener(_syncPageWithNav);
    DeepLinkService.instance.onHomeDisposed();
    _pageController.dispose();
    offListeners();
    super.dispose();
  }

  /// Switches back to the Home tab (used when back is pressed from any
  /// other bottom-nav tab).
  void _goToHomeTab(NavigationController navProvider) {
    _markVisited(0);
    _pageController.jumpToPage(0);
    navProvider.updateIndex(0);
  }

  Future<void> _handleBackPress(NavigationController navProvider) async {
    if (navProvider.currentIndex != 0) {
      _goToHomeTab(navProvider);
      return;
    }
    await _showExitConfirmationDialog();
  }

  Future<void> _showExitConfirmationDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'exit_app'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('exit_app_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'exit'.tr,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavigationController>(
      builder: (_) =>
          GetBuilder<SessionController>(builder: (_) => _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final navProvider = Get.find<NavigationController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(navProvider);
      },
      child: Scaffold(
        backgroundColor: context.shellBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    navProvider.updateIndex(index);
                    _markVisited(index);
                  },
                  children: [
                    _buildTab(0, const HomeTab()),
                    _buildTab(1, const MessagesTab()),
                    _buildTab(2, const FollowTab()),
                    _buildTab(3, const RecentCallsTab()),
                    _buildTab(4, const ProfileTab()),
                  ],
                ),
              ),

              // Bottom navigation bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: context.shellSurface,
                  boxShadow: [
                    BoxShadow(
                      color: context.isAppDarkMode
                          ? Colors.black45
                          : const Color(0x1A000000),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem(
                      "home".tr,
                      0,
                      navProvider,
                      svg: "assets/icons/home.svg",
                      svgFilled: "assets/icons/home_filled.svg",
                    ),
                    _buildBottomNavItem(
                      "message".tr,
                      1,
                      navProvider,
                      badgeText: _badge(
                        Get.find<SessionController>().session?.unReadMessages,
                      ),
                      svg: "assets/icons/messages.svg",
                      svgFilled: "assets/icons/messages_filled.svg",
                    ),
                    _buildBottomNavItem(
                      "following".tr,
                      2,
                      navProvider,
                      svg: "assets/icons/followers_followings.svg",
                      svgFilled: "assets/icons/follwings_followers_filled.svg",
                    ),
                    _buildBottomNavItem(
                      "recent".tr,
                      3,
                      navProvider,
                      badgeText: _badge(
                        Get.find<SessionController>().session?.unseen,
                      ),
                      svg: "assets/icons/calls.svg",
                      svgFilled: "assets/icons/call_filled.svg",
                    ),
                    _buildBottomNavItem(
                      "profile".tr,
                      4,
                      navProvider,
                      svg: "assets/icons/profile.svg",
                      svgFilled: "assets/icons/profile_filled.svg",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _badge(int? count) =>
      (count == null || count == 0) ? null : count.toString();

  /// Returns the real tab the first time it's visited; a shimmer
  /// placeholder before that, so the tab's own fetch (in its initState)
  /// doesn't fire until the user actually opens it.
  Widget _buildTab(int index, Widget realTab) {
    return _visitedTabs.contains(index) ? realTab : const _LazyTabPlaceholder();
  }

  Widget _buildBottomNavItem(
    String title,
    int index,
    NavigationController navProvider, {
    String? badgeText,
    required String svg,
    required String svgFilled,
  }) {
    bool isActive = navProvider.currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _markVisited(index);
          _pageController.jumpToPage(index);
          navProvider.updateIndex(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isActive)
                        SvgPicture.asset(
                          svg,
                          colorFilter: ColorFilter.mode(
                            context.shellIconInactive,
                            BlendMode.srcIn,
                          ),
                          // Following's icon is visually smaller than the
                          // others at 24, so it gets a bump. Keyed off the
                          // tab index (not the translated title) so this
                          // still works once "following".tr isn't English.
                          width: index == 2 ? 28 : 24,
                          height: index == 2 ? 28 : 24,
                        ),
                      AnimatedScale(
                        scale: isActive ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        child: SvgPicture.asset(
                          svgFilled,
                          width: 24,
                          height: 24,
                          // The asset's own baked-in colors were designed to
                          // sit on a white nav bar and read fine in light
                          // mode as-is (left untouched here). On the dark
                          // surface they'd blend in, so only dark mode gets
                          // a tint override.
                          colorFilter: context.isAppDarkMode
                              ? const ColorFilter.mode(
                                  AppDarkColors.accent,
                                  BlendMode.srcIn,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Positioned(
                    top: -8,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B13E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? context.shellTextPrimary
                    : context.shellIconInactive,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The one place the notification permission system prompt is actually
  // requested — moved here (from app startup in NotificationHelper) so it
  // shows up once the person is logged in and on Home, not on top of the
  // splash/auth screens before they've even signed in.
  void requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  void setuplisteners() {
    final socket = sl<SocketService>();

    socket.on('user_live', (data) {
      print("******");
      print(data);
      final userId = data['user_id'];
      // Get.bottomSheet(Text("data"));
      final stream = LiveStreamModel.fromJson(data['data']['liveStream']);

      Get.find<DiscoverController>().onUserLive(userId, stream);
      Get.find<DiscoverController>().fetchActiveLives();
    });

    socket.on('user_end_live', (data) {
      final userId = data['user_id'];
      Get.find<DiscoverController>().onUserEndLive(userId);
      Get.find<DiscoverController>().fetchActiveLives();
    });

    socket.on('user_connected', (data) {
      final userId = data['user_id'];
      Get.find<DiscoverController>().onUserConnected(userId);
      Get.find<DiscoverController>().fetchOnlineClients();
      context.read<MessagesTabViewModel>().fetchSuggestedClients();
    });

    socket.on('user_disconnected', (data) {
      final userId = data['user_id'];
      Get.find<DiscoverController>().onUserDisConnected(userId);
      context.read<MessagesTabViewModel>().fetchSuggestedClients();
    });
  }

  void offListeners() {
    final socket = sl<SocketService>();

    socket.off('user_live');

    socket.off('user_end_live');

    socket.off('user_connected');

    socket.off('user_disconnected');
  }
}

// ─── Lazy-tab placeholder ───────────────────────────────────────────────────
// Shown for the instant a not-yet-visited bottom-nav tab briefly exists in
// the PageView tree before its real widget swaps in. Each real tab already
// renders its own shimmer while its data loads, so this is just a generic
// stand-in to avoid a blank frame.

class _LazyTabPlaceholder extends StatelessWidget {
  const _LazyTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: context.shellSkeleton,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: context.shellSkeleton,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: context.shellSkeleton,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
