import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import '../home/presentation/controllers/navigation_controller.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/widgets/app_search_field.dart';
import '../profile/profile_screen.dart';
import 'follow_user_model.dart';
import 'followings_followers_provider.dart';

import '../session/presentation/controllers/session_controller.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingFragmentState();
}

class _FollowingFragmentState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pass your target context userId string safely here
      final String targetUserId =
          Get.find<SessionController>().session!.user!.id;
      context.read<FollowingProvider>().loadFollowers(targetUserId);
      context.read<FollowingProvider>().loadFollowing(targetUserId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<NavigationController>(
      builder: (navProvider) {
        return Scaffold(
          backgroundColor: context.shellBackground,
          body: SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              opacity: 1.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutQuart,
                offset: Offset.zero,
                child: NestedScrollView(
                  physics: const ClampingScrollPhysics(),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: context.shellTextPrimary,
                            unselectedLabelColor: const Color(0xFF7A7A7A),
                            indicatorColor: context.shellTextPrimary,
                            indicatorSize: TabBarIndicatorSize.label,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                            tabs: const [
                              Tab(text: "Followers"),
                              Tab(text: "Following"),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    physics: const ClampingScrollPhysics(),
                    children: [_buildFollowersList(), _buildFollowingList()],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar() {
    return Row(
      children: [
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.shellTextPrimary,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AppSearchField(
              controller: _searchController,
              hintText: "search",
              onChanged: (v) {
                context.read<FollowingProvider>().updateLocalSearch(v);
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- Followers List ---
  Widget _buildFollowersList() {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        if (provider.followersState == FollowPageState.error) {
          return const Center(child: Text("Failed to load followers."));
        }
        if (provider.followersState == FollowPageState.empty) {
          final userId = Get.find<SessionController>().session!.user!.id;
          return RefreshIndicator(
            onRefresh: () => provider.loadFollowers(userId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .5,
                  child: const Center(
                    child: Text(
                      "No followers found.\nPull down to refresh",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final bool isLoading =
            provider.followersState == FollowPageState.loading;
        final list = isLoading
            ? List.generate(8, (i) => FollowUserModel.mock(i, "Follower Item"))
            : provider.filteredFollowers;

        return Skeletonizer(
          enabled: isLoading,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              Get.to(
                                TargetProfileScreen(
                                  userId: f.id,
                                  userImage: f.profileImage,
                                  userName: f.name,
                                  index: 0,
                                ),
                              );
                            },
                      child: Hero(
                        tag: isLoading
                            ? 'loading_follower_$i'
                            : '${f.profileImage}_follower_${f.id}',
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: context.shellAvatarPlaceholder,
                          backgroundImage: AvatarHelper.resolve(f.profileImage),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        f.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FollowHeart(user: f, isLoading: isLoading),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Following List ---
  Widget _buildFollowingList() {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        if (provider.followingState == FollowPageState.error) {
          return const Center(child: Text("Failed to load following."));
        }
        if (provider.followingState == FollowPageState.empty) {
          final userId = Get.find<SessionController>().session!.user!.id;
          return RefreshIndicator(
            onRefresh: () => provider.loadFollowing(userId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .5,
                  child: const Center(
                    child: Text(
                      "No matching following found.\nPull down to refresh",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final bool isLoading =
            provider.followingState == FollowPageState.loading;
        final list = isLoading
            ? List.generate(6, (i) => FollowUserModel.mock(i, "Following Item"))
            : provider.filteredFollowing;

        return Skeletonizer(
          enabled: isLoading,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final u = list[i];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: FollowingUserRow(
                  name: u.name,
                  avatarUrl: u.profileImage,
                  isOnline: u.isLive,
                  index: i,
                  userId: u.id,
                  isLoading: isLoading,
                  trailing: FollowHeart(user: u, isLoading: isLoading),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- Sticky Tab Bar Delegate ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: context.shellSurface, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// --- Following User Row ---
class FollowingUserRow extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final int index;
  final String userId;
  final bool isLoading;

  /// Shown at the end of the row (the follow heart).
  final Widget? trailing;

  const FollowingUserRow({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.isOnline = false,
    required this.index,
    required this.userId,
    this.isLoading = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      Get.to(
                        TargetProfileScreen(
                          userId: userId,
                          userImage: avatarUrl,
                          userName: name,
                          index: 0,
                        ),
                      );
                    },
              child: Hero(
                tag: isLoading
                    ? 'loading_following_$index'
                    : '${avatarUrl}_following_${userId}_$index',
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: context.shellAvatarPlaceholder,
                  backgroundImage: AvatarHelper.resolve(avatarUrl),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10C32B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
        //  SvgPicture.asset(AssetsManager.chatFollwing, width: 24),
        //  const SizedBox(width: 16),
        // SvgPicture.asset(AssetsManager.videoFollwing, width: 28),
      ],
    );
  }
}

// --- Follow heart ---
// Filled heart + "Friends" = mutual follow. Outline heart = one-way.
// Tap: follow (if I don't follow them yet) or unfollow after confirming.
class FollowHeart extends StatelessWidget {
  final FollowUserModel user;
  final bool isLoading;

  const FollowHeart({super.key, required this.user, this.isLoading = false});

  static const _purple = Color(0xFF8B2CF5);

  Future<void> _onTap(BuildContext context) async {
    final provider = context.read<FollowingProvider>();
    final ownerId = Get.find<SessionController>().session?.user?.id;

    if (user.isFollowing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Unfollow',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Stop following ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Unfollow',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await provider.toggleFollow(user, ownerId: ownerId);
  }

  @override
  Widget build(BuildContext context) {
    final friend = user.isFriend;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (friend && !isLoading) ...[
          const Text(
            'Friends',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isLoading ? null : () => _onTap(context),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                friend ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(friend),
                color: _purple,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
