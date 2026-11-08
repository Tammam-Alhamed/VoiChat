import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/helpers/wallet_helper.dart';
import 'package:shoeebapk/features/leader_board/leader_board_screen.dart';
import 'package:shoeebapk/features/settings/recharge/recharge_screen.dart';

import '../../../notification/notification_screen.dart';
import 'country_selection_screen.dart';
import '../../../search_by_id/search_by_id_screen.dart';
import '../../../home/presentation/controllers/navigation_controller.dart';
import '../widgets/home_tab_content.dart';
import '../../../../core/widgets/sliver_app_bar_delegate.dart';
import '../../../../core/themes/app_dark_colors.dart';

import '../../../session/presentation/controllers/session_controller.dart';
import '../controllers/discover_controller.dart';
import '../../../live/presentation/controllers/live_entry_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  HomeTabState createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  int index = 0;

  final List<String> _tabs = ["Home", "Live", "Online", "Country"];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabs.length, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          index = _tabController.index;
        });

        // Each sub-tab loads its own data the first time it's opened
        // (guarded by TabStatus.idle), instead of all four firing at once.
        Get.find<DiscoverController>().fetchTabIfIdle(_tabs[index]);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load the tab that's actually visible on entry;
      // the rest load lazily as the user switches to them.
      Get.find<DiscoverController>().fetchTabIfIdle(_tabs[index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionController>(
      builder: (_) => _buildSessionScope(context),
    );
  }

  Widget _buildSessionScope(BuildContext context) {
    return GetBuilder<NavigationController>(
      builder: (navProvider) {
        final bool isActive = navProvider.currentIndex == 0;

        return Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniCenterDocked,

          floatingActionButton: InkWell(
            // Resumes a still-running live session if there is one;
            // otherwise opens the pre-live setup screen (goal, filters,
            // share) — the broadcast only starts from its Go Live button.
            onTap: () => Get.find<LiveEntryController>().openGoLive(),
            child: SvgPicture.asset(AssetsManager.liveVideoButton),
          ),

          backgroundColor: context.shellBackground,

          body: SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              opacity: isActive ? 1.0 : 0.0,

              child: AnimatedSlide(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutQuart,
                offset: isActive ? Offset.zero : const Offset(0, 0.04),

                child: NestedScrollView(
                  floatHeaderSlivers: true,
                  physics: const ClampingScrollPhysics(),

                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: false,
                        surfaceTintColor: context.shellBackground,
                        elevation: 0,
                        backgroundColor: context.shellBackground,
                        automaticallyImplyLeading: false,
                        titleSpacing: 0,

                        title: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Get.to(RechargeCenterScreen()),
                                borderRadius: BorderRadius.circular(23),

                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23),
                                    color: context.themedColor(
                                      const Color(0xFFF2F2F2),
                                      AppDarkColors.card,
                                    ),
                                  ),

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),

                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Image.asset(
                                          "assets/moke/coin.png",
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                      Text(
                                        WalletHelper.format(
                                          Get.find<SessionController>()
                                              .session!
                                              .user!
                                              .walletBalance,
                                        ),
                                        style: TextStyle(
                                          color: context.shellTextPrimary,
                                          fontSize: 15,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                        ),
                                        width: 21,
                                        height: 21,
                                        child: const Center(
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(),

                              IconButton(
                                icon: SvgPicture.asset(
                                  "assets/icons/cub.svg",
                                  width: 21,
                                  colorFilter: context.isAppDarkMode
                                      ? const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                ),
                                onPressed: () =>
                                    Get.to(const LeaderboardScreen()),
                              ),

                              IconButton(
                                icon: SvgPicture.asset(
                                  "assets/icons/search.svg",
                                  width: 23,
                                  colorFilter: context.isAppDarkMode
                                      ? const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                ),
                                onPressed: () => Get.to(SearchByIdScreen()),
                              ),

                              IconButton(
                                icon: SvgPicture.asset(
                                  "assets/icons/notification.svg",
                                  width: 21,
                                  colorFilter: context.isAppDarkMode
                                      ? const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        )
                                      : null,
                                ),
                                onPressed: () => Get.to(NotificationsScreen()),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPersistentHeader(
                        pinned: true,
                        delegate: SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,

                            padding: const EdgeInsets.symmetric(horizontal: 10),

                            labelPadding: const EdgeInsets.only(right: 10),

                            indicatorSize: TabBarIndicatorSize.label,

                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 3,
                                color: context.shellTextPrimary,
                              ),
                              insets: EdgeInsets.zero,
                            ),

                            dividerColor: context.themedColor(
                              const Color(0xFFF5F5F5),
                              AppDarkColors.divider,
                            ),

                            dividerHeight: 1,

                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.shellTextPrimary,
                            ),

                            unselectedLabelStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: context.themedColor(
                                const Color(0xFF202020),
                                AppDarkColors.textSecondary,
                              ),
                            ),

                            splashFactory: NoSplash.splashFactory,

                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),

                            tabs: _tabs.map((t) => Tab(text: t)).toList(),
                          ),
                        ),
                      ),
                    ];
                  },

                  body: TabBarView(
                    controller: _tabController,
                    physics: const ClampingScrollPhysics(),

                    children: [
                      const HomeTabContent(tabName: 'Home'),

                      const HomeTabContent(tabName: 'Live'),

                      const HomeTabContent(tabName: 'Online'),

                      HomeTabContent(
                        tabName: 'Country',
                        showFilter: true,
                        onFilterTap: () => _onCountryFilterTap(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCountryFilterTap(BuildContext context) {
    final viewModel = Get.find<DiscoverController>();

    Get.to<String?>(
      () => CountrySelectionScreen(initialValue: viewModel.selectedCountry),
    )?.then((countryCode) {
      // If countryCode is null, it means user cleared
      // filter or just went back.
      viewModel.setCountryFilter(countryCode);
    });
  }
}
