import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/extentions.dart';

import '../../../../core/themes/app_dark_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../profile/profile_screen.dart';
import '../../../../core/widgets/premium_grid_card.dart';
import '../../../../core/domain/entities/client_user.dart';
import '../controllers/followings_controller.dart';
import '../../../live/presentation/controllers/live_entry_controller.dart';

class FollowTab extends StatefulWidget {
  const FollowTab({super.key});

  @override
  State<FollowTab> createState() => _FollowTabState();
}

class _FollowTabState extends State<FollowTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String searchQuery = '';
  late AnimationController _listController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<FollowingsController>().getUserFollowings();
    });
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildContentState()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.shellBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Followings").fs22.bold,
          const SizedBox(height: 8),
          AppSearchField(
            hintText: "Search following...",
            onChanged: (v) => setState(() => searchQuery = v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContentState() {
    return GetBuilder<FollowingsController>(
      builder: (provider) {
        // 1. Error State
        if (provider.pageState == PageState.error) {
          return AppStateView.error(
            message: provider.error,
            onRetry: () => provider.getUserFollowings(),
          );
        }

        // Filter data based on search queries
        final filteredItems = provider.followings.where((item) {
          return (item.name ?? '').toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
        }).toList();

        // 2. Empty State (Evaluated when loaded or if search returns nothing)
        if (provider.pageState == PageState.empty ||
            (provider.pageState == PageState.loaded && filteredItems.isEmpty)) {
          // No refresh button — pull down to refresh instead, same as
          // every other empty state in the app.
          return RefreshIndicator(
            onRefresh: () => provider.getUserFollowings(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .7,
                  child: AppStateView.empty(
                    icon: Icons.people_outline_rounded,
                    title: searchQuery.isEmpty
                        ? "No followings yet"
                        : "No results found",
                    message: "Pull down to refresh",
                  ),
                ),
              ],
            ),
          );
        }

        // 3. Loading (Skeletonizer) & 4. Loaded States
        final isLoading = provider.pageState == PageState.loading;

        return Skeletonizer(
          enabled: isLoading,
          child: RefreshIndicator(
            onRefresh: () => provider.getUserFollowings(),
            child: _buildGrid(isLoading ? _dummyFollowings() : filteredItems),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<ClientUser> items) {
    return GridView.builder(
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        final animation = CurvedAnimation(
          parent: _listController,
          curve: Interval(
            (0.1 * index).clamp(0, 1.0),
            1.0,
            curve: Curves.easeOutQuart,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: PremiumGridCard(
              bgUrl: item.profileImage,
              avatarUrl: item.profileImage,
              name: item.name ?? 'User Name',
              liveViews: item.streams!.isEmpty
                  ? "0"
                  : item.streams!.first.viewersCount.toString(),
              diamonds: item.followersCount.toString(),
              isLive: item.isLive ?? false,
              userId: item.id ?? '',
              index: index,
              isOnline: item.isOnline ?? false,
              viewsIconUrl: 'assets/icons/views.png',
              onTap: () {
                if (!(item.isLive ?? false)) {
                  Get.to(
                    () => TargetProfileScreen(
                      userId: item.id,
                      userName: item.name ?? '',
                      userImage: item.profileImage ?? '',
                      index: index,
                    ),
                  );
                  return;
                }

                if (item.streams != null && item.streams!.isNotEmpty) {
                  Get.find<LiveEntryController>().joinLiveStream(
                    item.streams!.first,
                    item,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Generates mocking instances to form skeleton shapes during async calls
  List<ClientUser> _dummyFollowings() {
    return List.generate(
      6,
      (index) => ClientUser(
        id: 'dummy_$index',
        name: 'Loading Name...',
        profileImage: '',
        followersCount: 0,
        isLive: false,
        isOnline: false,
        streams: [],
      ),
    );
  }
}
