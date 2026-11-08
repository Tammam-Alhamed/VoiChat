import 'package:flutter/material.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/helpers/image_crop_helper.dart';
import 'package:shoeebapk/core/widgets/action_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/themes/app_dark_colors.dart';
import '../../../../../core/helpers/avatar_helper.dart';
import '../viewmodel/profile_tab_viewmodel.dart';
import '../widget/full_screen_image_viewer.dart';
import '../widget/profile_loaded_content.dart';
import '../widget/profile_loading_view.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    context.read<ProfileTabViewModel>().reset();
    context.read<ProfileTabViewModel>().getMyProfile();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showImageOptions(BuildContext context) {
    final provider = context.read<ProfileTabViewModel>();

    // The default avatar is the only thing left once profile_image is
    // cleared (see removeProfileImage — it PUTs an empty string). A Google
    // auto-fetched photo (googleusercontent.com) doesn't count as "real"
    // either — the user never actually chose it — so Remove Photo stays
    // hidden for that case too; see AvatarHelper.hasRealPhoto.
    final currentImage = provider.profile?.data?.profileImage;
    final hasRealPhoto = AvatarHelper.hasRealPhoto(currentImage);

    showActionBottomSheet(
      context,
      options: [
        ActionSheetOption(
          icon: Icons.photo_camera,
          text: "Take Photo",
          onTap: () async {
            // Instagram-style flow: pan/zoom inside a circular crop frame
            // before the photo is uploaded anywhere.
            final cropped = await ImageCropHelper.pickAndCropProfileImage(
              ImageSource.camera,
            );
            if (cropped != null) {
              provider.updateProfileImage(cropped);
            }
          },
        ),
        ActionSheetOption(
          icon: Icons.photo_library,
          text: "Choose from Gallery",
          onTap: () async {
            final cropped = await ImageCropHelper.pickAndCropProfileImage(
              ImageSource.gallery,
            );
            if (cropped != null) {
              provider.updateProfileImage(cropped);
            }
          },
        ),
        // Omitted entirely (not just disabled) when there's no real photo
        // to remove — showing a greyed-out "Remove Photo" row when the
        // avatar is already the default makes no sense.
        if (hasRealPhoto)
          ActionSheetOption(
            icon: Icons.delete,
            text: "Remove Photo",
            color: Colors.red,
            onTap: () => provider.removeProfileImage(),
          ),
      ],
    );
  }

  void _openFullScreenImage(BuildContext context, String? profileImage) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Preview",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          FullScreenImageViewer(imageUrl: profileImage),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String postId) {
    final provider = context.read<ProfileTabViewModel>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: context.shellSurface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Post?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to remove this post? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          provider.deletePost(postId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: Consumer<ProfileTabViewModel>(
        builder: (context, provider, child) {
          switch (provider.pageState) {
            case PageState.loading:
              return const ProfileLoadingView();

            case PageState.error:
              return ProfileErrorView(
                message: provider.error ?? 'Failed to load your profile.',
                onRetry: provider.retry,
              );

            case PageState.empty:
              return ProfileEmptyView(onRetry: provider.retry);

            case PageState.loaded:
              return ProfileLoadedContent(
                provider: provider,
                pageController: _pageController,
                selectedTabIndex: _selectedTabIndex,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                onPageChanged: (index) =>
                    setState(() => _selectedTabIndex = index),
                onTabTapped: _onTabTapped,
                onAvatarTap: (context, image) =>
                    _openFullScreenImage(context, image),
                onEditPhotoTap: () => _showImageOptions(context),
                onPostLongPress: (postId) =>
                    _showDeleteConfirmationDialog(context, postId),
              );
          }
        },
      ),
    );
  }
}

// ─── Loaded-state content (unchanged design, extracted into its own widget) ─

// ─── Shared sub-widgets ─────────────────────────────────────────────────────
