import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart'; // تأكد من استيراد مكتبة السكيلتونايزر هنا
import 'package:shoeebapk/core/country_helper.dart';
import 'package:shoeebapk/features/chat/chat_screen.dart';
import 'package:shoeebapk/features/profile/state/target_profile_provider.dart';
import 'package:shoeebapk/core/themes/app_dark_colors.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/widgets/profile_photo_viewer.dart';
import 'package:shoeebapk/core/helpers/wallet_helper.dart';
import '../calls/state/calls_provider.dart';
import '../home/tabs/profile/widget/state_item.dart';
import 'state/profile_page_state.dart';
import 'widgets/block_user_dialog.dart';
import 'widgets/report_user_dialog.dart';
import 'widgets/states_widgets.dart';

class TargetProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userImage;
  final int index;

  const TargetProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.index,
  });

  @override
  State<TargetProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<TargetProfileScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late PageController _pageController; // متحكم السحب (Swipe)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // استدعاء الباكيند عند الدخول للشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TargetProfileProvider>().reset(userId: widget.userId);
      context.read<TargetProfileProvider>().getProfile(userId: widget.userId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(iconPath: "assets/icons/gallery1.png", index: 0),
          SizedBox(width: Get.width / 3),
          _buildTabItem(iconPath: "assets/icons/gallery2.png", index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String iconPath, required int index}) {
    final isSelected = _selectedTabIndex == index;
    const activeColor = Color(0xFF7247EF);
    const inactiveColor = Colors.grey;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
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

  /* Widget _buildPhotosGrid(TargetProfileProvider provider) {
    final posts = provider.profile?.posts ?? [];
    return GridView.builder(
      key: const ValueKey('photos_grid'),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.9,
      ),
      itemCount: provider.pageState == ProfilePageState.loading
          ? 4
          : posts.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            image: provider.pageState == ProfilePageState.loading
                ? null
                : DecorationImage(
                    image: CachedNetworkImageProvider(posts[index].mediaUrl),
                    fit: BoxFit.cover,
                  ),
          ),
        );
      },
    );
  }
*/
  /* Widget _buildNoVideosPlaceholder() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        key: const ValueKey('no_videos'),
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_off,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No Videos Yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "When you post videos, they will appear here",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
*/
  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TargetProfileProvider>(
      builder: (context, provider, child) {
        // فحص الستيتس الكبرى وتحويلها للويدجتس المنفصلة والنظيفة
        if (provider.pageState == ProfilePageState.banned) {
          return ProfileBannedWidget(
            reason: provider.banReason ?? "",
            onBack: () => Get.back(),
          );
        }
        if (provider.pageState == ProfilePageState.blocked) {
          return ProfileBlockedWidget(onBack: () => Get.back());
        }
        if (provider.pageState == ProfilePageState.empty) {
          return ProfileEmptyWidget(onBack: () => Get.back());
        }
        if (provider.pageState == ProfilePageState.error) {
          return ProfileErrorWidget(
            error: provider.error ?? "Unknown Error",
            onRetry: provider.retry,
          );
        }

        // إذا كانت الستيت تحميل (Loading) أو جاهزة (Loaded)
        final isLoading = provider.pageState == ProfilePageState.loading;

        return Scaffold(
          backgroundColor: context.shellBackground,
          body: SafeArea(
            child: NestedScrollView(
              // تضمن ثبات هيكلية الصفحة مع الـ PageView والسكرول
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Icon(Icons.arrow_back_ios_new_rounded),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              color: Colors.white,
                              onSelected: (value) {
                                switch (value) {
                                  case 'share':
                                    /*  Get.dialog(
                                      ReportUserDialog(
                                        userId: widget.userId,
                                        userName: widget.userName,
                                      ),
                                    );*/
                                    break;
                                  case 'report':
                                    Get.dialog(
                                      ReportUserDialog(
                                        userId: widget.userId,
                                        userName: widget.userName,
                                      ),
                                    );
                                    break;
                                  case 'block':
                                    Get.dialog(
                                      BlockUserDialog(
                                        userId: widget.userId,
                                        userName: widget.userName,
                                      ),
                                    );

                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.share,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'share user',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuItem(
                                  value: 'report',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.flag_outlined,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Report User',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                PopupMenuItem(
                                  value: 'block',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.block,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Block User',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Profile Info — avatar/name/location alignment and
                      // sizing mirror ProfileLoadedContent's own header
                      // (_buildProfileHeader) exactly, so "my profile" and
                      // any other user's profile look like the same design.
                      // Basic fields come straight from the constructor
                      // params so they render instantly, without waiting.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Tap the photo to view it full screen with
                            // pinch-to-zoom (uses the freshest photo once
                            // the profile has loaded).
                            GestureDetector(
                              onTap: () => ProfilePhotoViewer.open(
                                context,
                                AvatarHelper.hasRealPhoto(
                                      provider.profile?.profileImage,
                                    )
                                    ? provider.profile!.profileImage
                                    : widget.userImage,
                                heroTag:
                                    'profile_avatar_${widget.userName}_${widget.index}',
                              ),
                              child: Hero(
                                tag:
                                    'profile_avatar_${widget.userName}_${widget.index}',
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[100],
                                  radius: 35,
                                  backgroundImage: AvatarHelper.resolve(
                                    widget.userImage,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Hero(
                                        tag:
                                            'profile_name_${widget.userName}_${widget.index}',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            widget.userName,
                                            style: TextStyle(
                                              color: context.shellTextPrimary,
                                              fontSize: context.width * .045,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // هذا الجزء يدخل في تأثير الـ Skeletonizer فقط إن كان قيد التحميل
                                      Skeleton.keep(
                                        child:
                                            !isLoading &&
                                                (provider.profile?.isVerified ??
                                                    false)
                                            ? SizedBox(
                                                width: 17,
                                                height: 17,
                                                child: Image.asset(
                                                  "assets/moke/verified.png",
                                                  color: const Color(
                                                    0xFF7247EF,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // استخدام الـ Skeletonizer لتغطية الأجزاء التي تطلب تحميل من السيرفر فقط
                                  Skeletonizer(
                                    enabled: isLoading,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: Image.asset(
                                            "assets/icons/location.png",
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isLoading
                                              ? "Loading Country, 00 y.o."
                                              : "${CountryHelper.getCountryNameFromCountryCode(provider.profile!.country)}, ${provider.profile!.birthdate == null ? "Unknown" : calculateAge(DateTime.parse(provider.profile!.birthdate!))} y.o.",
                                          style: const TextStyle(
                                            color: Color(0xFF7A7A7A),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Stats row — moved out to its own full-width row
                      // (same spaceAround layout, no extra horizontal
                      // padding) to match ProfileLoadedContent exactly,
                      // instead of being squeezed into the name column.
                      Skeletonizer(
                        enabled: isLoading,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatItem(
                              number: isLoading
                                  ? "000"
                                  : WalletHelper.format(
                                      provider.profile!.totalEarnings,
                                    ),
                              label: "Earned",
                            ),
                            StatItem(
                              number: isLoading
                                  ? "000"
                                  : provider.profile!.followersCount
                                        .toString()
                                        .replaceFirst(".00", ""),
                              label: "Followers",
                            ),
                            StatItem(
                              number: isLoading
                                  ? "000"
                                  : provider.profile!.followingCount
                                        .toString()
                                        .replaceFirst(".00", ""),
                              label: "Following",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bio Section — optional. If the user hasn't written
                      // one, this simply renders nothing instead of a
                      // placeholder sentence, so the layout stays clean.
                      if (isLoading)
                        Skeletonizer(
                          enabled: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 33),
                            child: Text(
                              "Loading long user biography content goes here...",
                              style: TextStyle(
                                color: context.shellTextPrimary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      else if ((provider.profile!.bio ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 33),
                          child: Text(
                            provider.profile!.bio!,
                            style: TextStyle(
                              color: context.shellTextPrimary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Skeletonizer(
                        enabled: isLoading,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: Row(
                            children: [
                              (!isLoading && provider.profile!.isFollowing)
                                  ? Expanded(
                                      // Unfollow mirrors Message's exact
                                      // look (light bg + black text) — the
                                      // red "Follow" color is only shown
                                      // while not-yet-following, and
                                      // switches back the instant you
                                      // unfollow (driven by isFollowing).
                                      child: Skeleton.ignore(
                                        child: _AnimatedActionButton(
                                          text: "Unfollow",
                                          textColor: Colors.black,
                                          bgColor: const Color(0xFFEDEDED),
                                          onTap: () => provider.unFollowUser(
                                            userId: widget.userId,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Expanded(
                                      child: Skeleton.ignore(
                                        child: _AnimatedActionButton(
                                          text: "Follow",
                                          textColor: Colors.white,
                                          bgColor: const Color(0xFFFF3C1F),
                                          onTap: () => provider.followUser(
                                            userId: widget.userId,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Skeleton.ignore(
                                  child: _AnimatedActionButton(
                                    text: "Message",
                                    textColor: Colors.black,
                                    bgColor: const Color(0xFFEDEDED),
                                    onTap: () {
                                      Get.to(
                                        ChatScreen(
                                          receiverId: widget.userId,
                                          userName: widget.userName,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Skeleton.ignore(
                                  child: _AnimatedVideoCallButton(
                                    userId: widget.userId,
                                    userImage: widget.userImage,
                                    userName: widget.userName,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tabs Area (التصميم الأصلي الثابت للزبون)
                      _buildTabs(),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: const Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
              // الـ Body تم تحويله لـ PageView لدعم الـ Swipe الكامل والناعم كما طلبت
              body: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                children: [
                  Skeletonizer(
                    enabled: isLoading,
                    child: _buildPhotosGrid(provider),
                  ),
                  _buildNoVideosPlaceholder(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosGrid(TargetProfileProvider provider) {
    final posts = provider.profile?.posts ?? [];

    // إذا ما في صور، اعرض رسالة ثابتة بدون Scroll
    if (provider.pageState != ProfilePageState.loading && posts.isEmpty) {
      return SizedBox(
        key: const ValueKey('no_photos'),
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No Photos Yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "When you post photos, they will appear here",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // في حال وجود صور، خلي الـ Grid هو اللي يعمل Scroll
    return GridView.builder(
      key: const ValueKey('photos_grid'),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.9,
      ),
      itemCount: provider.pageState == ProfilePageState.loading
          ? 4
          : posts.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            image: provider.pageState == ProfilePageState.loading
                ? null
                : DecorationImage(
                    image: CachedNetworkImageProvider(posts[index].mediaUrl),
                    fit: BoxFit.cover,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNoVideosPlaceholder() {
    // ثابت بدون Scroll
    return SizedBox(
      key: const ValueKey('no_videos'),
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_off,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No Videos Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you post videos, they will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Stat numbers now use the shared StatItem widget (imported from
// ProfileLoadedContent's own folder) instead of a locally duplicated
// look-alike, so the two profile pages can never visually drift apart.
class _AnimatedActionButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;
  const _AnimatedActionButton({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  // Height/radius match every other action button (Follow/Unfollow/Message/
  // Video call) exactly, so the row reads as one consistent button group.
  static const double _height = 42;
  static const double _radius = 21;

  @override
  Widget build(BuildContext context) {
    return _HoverableButton(
      onTap: onTap,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_radius),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Same gradient as the app's main purple-gradient buttons (Add Post, etc. —
// see _buildAddPostButton in profile_loaded_content.dart) so "Video call"
// reads as the same family of primary action, not a one-off color. Same
// height/radius as the other three action buttons for a consistent row.
class _AnimatedVideoCallButton extends StatelessWidget {
  final String userId;
  final String userName;
  final String userImage;
  const _AnimatedVideoCallButton({
    required this.userId,
    required this.userName,
    required this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverableButton(
      onTap: () {
        context.read<CallsProvider>().initiateCall(
          receiverId: userId,
          receiverName: userName,
          receiverImage: userImage,
          callType: 'video',
        );
      },
      child: Container(
        height: _AnimatedActionButton._height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_AnimatedActionButton._radius),
          // Matches _buildAddPostButton's gradient exactly.
          gradient: const LinearGradient(
            colors: [Color(0xFF7247EF), Color(0xFF7247EF)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Image.asset(
                "assets/icons/video_call.png",
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "Video call",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverableButton({required this.child, required this.onTap});
  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: widget.child,
        ),
      ),
    );
  }
}
