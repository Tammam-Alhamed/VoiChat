import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/country_helper.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/helpers/wallet_helper.dart';
import 'package:shoeebapk/features/settings/account_center_screen.dart';

import '../../../../../testlivekit/test_livekit_screen.dart';
import '../../../shared/widgets/add_photo_or_video_sheet.dart';
import '../viewmodel/profile_tab_viewmodel.dart';

import '../../../../follow/following_followers.dart';
import '../../../../../core/themes/app_dark_colors.dart';
import 'state_item.dart';

class ProfileLoadedContent extends StatelessWidget {
  final ProfileTabViewModel provider;
  final PageController pageController;
  final int selectedTabIndex;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTabTapped;
  final void Function(BuildContext context, String? image) onAvatarTap;
  final VoidCallback onEditPhotoTap;
  final ValueChanged<String> onPostLongPress;

  const ProfileLoadedContent({
    super.key,
    required this.provider,
    required this.pageController,
    required this.selectedTabIndex,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onPageChanged,
    required this.onTabTapped,
    required this.onAvatarTap,
    required this.onEditPhotoTap,
    required this.onPostLongPress,
  });
  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)} K';
    }
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 12),
                  _buildProfileHeader(context),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatItem(
                        number: WalletHelper.format(
                          provider.profile!.data!.totalEarnings,
                        ),
                        label: "Earned",
                      ),
                      InkWell(
                        onTap: () => Get.to(FollowingScreen()),
                        child: StatItem(
                          number: _formatNumber(
                            provider.profile!.data!.followersCount,
                          ),
                          label: "Followers",
                        ),
                      ),
                      InkWell(
                        onTap: () => Get.to(FollowingScreen()),
                        child: StatItem(
                          number: _formatNumber(
                            provider.profile!.data!.followingCount,
                          ),
                          label: "Following",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBio(context),
                  const SizedBox(height: 24),
                  _buildAddPostButton(context),
                  const SizedBox(height: 24),
                  _buildTabs(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ];
        },
        body: PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          children: [
            _buildPhotosGrid(context),
            _buildNoVideosPlaceholder(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'ID: ${provider.profile!.data!.profileId}',
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (provider.isBusy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 18),
          ],
          GestureDetector(
            onTap: () => Get.to(() => const TestLiveKitScreen()),
            child: const Icon(
              Icons.sensors,
              color: Color(0xff872EDF),
              size: 22,
            ),
          ),
          const SizedBox(width: 18),
          SvgPicture.asset(
            AssetsManager.share,
            semanticsLabel: 'share',
            width: 20,
            height: 20,
            colorFilter: context.isAppDarkMode
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: () => Get.to(() => const AccountCenterScreen()),
            child: SvgPicture.asset(
              AssetsManager.setting,
              semanticsLabel: 'setting',
              width: 20,
              height: 20,
              colorFilter: context.isAppDarkMode
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    // Falls back to the bundled default avatar when the user has no photo
    // set, or when the only photo on file is the one Google auto-fetched
    // (never something the user actually picked in-app) — see AvatarHelper.
    final imageProvider = AvatarHelper.resolve(
      provider.profile!.data!.profileImage,
    );
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => onAvatarTap(
                      context,
                      provider.profile!.data!.profileImage,
                    ),
                    child: CircleAvatar(
                      backgroundColor: context.shellAvatarPlaceholder,
                      radius: 35,
                      backgroundImage: imageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPhotoTap,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff872EDF),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          provider.profile!.data!.name,
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: context.width * .045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (provider.profile!.data!.isVerified)
                          SizedBox(
                            width: 17,
                            height: 17,
                            child: Image.asset(
                              "assets/moke/verified.png",
                              color: const Color(0xFF7247EF),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: Image.asset("assets/icons/location.png"),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${CountryHelper.getCountryNameFromCountryCode(provider.profile!.data!.country!)}, ${provider.profile!.data!.birthdate == null ? "Unknown" : calculateAge(DateTime.parse(provider.profile!.data!.birthdate!))} y.o.",
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildBio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 33),
      child: Text(
        provider.profile!.data!.bio ?? "This person hasn’t added a bio yet.",
        style: TextStyle(
          color: context.shellTextPrimary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAddPostButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => showAddPostSheet(context),
        child: Container(
          width: 235,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Add Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(iconPath: "assets/icons/gallery1.png", index: 0),
          SizedBox(width: context.width / 3),
          _buildTabItem(iconPath: "assets/icons/gallery2.png", index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String iconPath, required int index}) {
    final isSelected = selectedTabIndex == index;
    const activeColor = Color(0xFF7247EF);
    const inactiveColor = Colors.grey;

    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: Column(
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: isSelected ? activeColor : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(BuildContext context) {
    final posts = provider.posts;
    if (posts.isEmpty) {
      return const Center(
        child: Text("No posts yet", style: TextStyle(color: Colors.grey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.9,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isVideo = post.mediaType == 'video';
        final imageProvider = CachedNetworkImageProvider(post.mediaUrl);

        return GestureDetector(
          onLongPress: () => onPostLongPress(post.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoVideosPlaceholder(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.shellSkeleton,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_off,
                size: 40,
                color: context.shellTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No Videos Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.shellTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you post videos, they will appear here",
              style: TextStyle(fontSize: 14, color: context.shellTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
