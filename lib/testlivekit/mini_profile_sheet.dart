import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/country_helper.dart';
import 'package:shoeebapk/features/chat/chat_screen.dart';
import 'package:shoeebapk/features/profile/state/profile_page_state.dart';
import 'package:shoeebapk/features/profile/state/target_profile_provider.dart';
import 'package:shoeebapk/features/profile/widgets/block_user_dialog.dart';
import 'package:shoeebapk/features/profile/widgets/report_user_dialog.dart';

import '../core/helpers/store_helper.dart';
import '../core/helpers/toast_helper.dart';
import '../core/helpers/avatar_helper.dart';
import '../core/helpers/wallet_helper.dart';
import '../core/network/service_helper.dart';
import '../core/utils/api_status.dart';
import '../features/calls/state/calls_provider.dart';
import '../app/di/injection_container.dart';
import 'gifts_bottom_sheet.dart';

/// Opens the compact "mini profile" bottom sheet — same real profile data
/// and Follow/Message/Gift/Video actions as the full TargetProfileScreen,
/// but as an overlay so the live video keeps playing underneath instead of
/// navigating away from the room.
void showMiniProfileSheet(
  BuildContext context, {
  required String userId,
  required String userName,
  String? userImage,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => MiniProfileSheet(
      userId: userId,
      userName: userName,
      userImage: userImage,
    ),
  );
}

class MiniProfileSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;

  const MiniProfileSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
  });

  @override
  State<MiniProfileSheet> createState() => _MiniProfileSheetState();
}

class _MiniProfileSheetState extends State<MiniProfileSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TargetProfileProvider>();
      provider.reset(userId: widget.userId);
      provider.getProfile(userId: widget.userId);
    });
  }

  int _calculateAge(DateTime birthDate) {
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
      builder: (context, provider, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.68,
          decoration: const BoxDecoration(
            color: Color(0xE6141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(TargetProfileProvider provider) {
    if (provider.pageState == ProfilePageState.banned) {
      return _buildMessageState(
        provider.banReason ?? 'This account has been suspended',
      );
    }
    if (provider.pageState == ProfilePageState.blocked) {
      return _buildMessageState('You have blocked this user');
    }
    if (provider.pageState == ProfilePageState.error) {
      return _buildMessageState(
        provider.error ?? 'Unknown error',
        onRetry: provider.retry,
      );
    }
    if (provider.pageState == ProfilePageState.empty) {
      return _buildMessageState('User not found');
    }

    final isLoading = provider.pageState == ProfilePageState.loading;
    final profile = provider.profile;

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: AvatarHelper.resolve(
                            widget.userImage,
                          ),
                        ),
                        if (!isLoading && profile?.vipMember == true) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isLoading &&
                                  profile?.isVerified == true) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF8B3EE8),
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoading
                                ? 'Loading...'
                                : '${CountryHelper.getCountryNameFromCountryCode(profile?.country ?? '')}'
                                      '${profile?.birthdate != null ? ', ${_calculateAge(DateTime.parse(profile!.birthdate!))} y.o.' : ''}',
                            style: const TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _statItem(
                                isLoading
                                    ? '--'
                                    : WalletHelper.format(
                                        profile!.totalEarnings,
                                      ),
                                'Earned',
                              ),
                              const SizedBox(width: 20),
                              _statItem(
                                isLoading ? '--' : '${profile!.followersCount}',
                                'Followers',
                              ),
                              const SizedBox(width: 20),
                              _statItem(
                                isLoading ? '--' : '${profile!.followingCount}',
                                'Following',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onPressed: () => _showMoreMenu(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isLoading
                      ? ''
                      : (profile?.bio?.isNotEmpty == true
                            ? profile!.bio!
                            : 'This person has no bio yet.'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: isLoading
                            ? '...'
                            : (profile?.isFollowing == true
                                  ? 'Message'
                                  : '+ Follow'),
                        onTap: isLoading
                            ? null
                            : () {
                                if (profile?.isFollowing == true) {
                                  Get.to(
                                    () => ChatScreen(
                                      receiverId: widget.userId,
                                      userName: widget.userName,
                                      userAvatar: widget.userImage,
                                    ),
                                  );
                                } else {
                                  provider.followUser(userId: widget.userId);
                                }
                              },
                        color: const Color(0xFFFF3A54),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _circleIconButton(
                      child: const Text('🎁', style: TextStyle(fontSize: 18)),
                      onTap: () => _sendProfileGift(context),
                    ),
                    const SizedBox(width: 10),
                    _circleIconButton(
                      icon: Icons.videocam,
                      color: const Color(0xFF8B3EE8),
                      onTap: () {
                        context.read<CallsProvider>().initiateCall(
                          receiverId: widget.userId,
                          receiverName: widget.userName,
                          receiverImage: widget.userImage,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isLoading && (profile?.posts.isNotEmpty ?? false)) ...[
                  const Text(
                    'Posts',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profile!.posts.length > 6
                        ? 6
                        : profile.posts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.8,
                        ),
                    itemBuilder: (context, index) {
                      final post = profile.posts[index];
                      final thumb = post.thumbnail ?? post.mediaUrl;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    IconData? icon,
    Widget? child,
    Color color = const Color(0xFF6044FF),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child ?? Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMessageState(String message, {VoidCallback? onRetry}) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text(
                'Report User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.dialog(
                  ReportUserDialog(
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text(
                'Block User',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.dialog(
                  BlockUserDialog(
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Real gift send from the mini profile — same catalog + wallet flow as
  /// the chat screen's gift button (`_openGiftSheet` in chat_screen.dart),
  /// context 'profile' since it's a direct person-to-person gift, not tied
  /// to a live session.
  Future<void> _sendProfileGift(BuildContext context) async {
    final gift = await showGiftBottomSheet(context);
    if (gift == null || !context.mounted) return;

    final serviceHelper = sl<ServiceHelper>();
    final token = sl<StoreHelper>().getAccessToken();
    final response = await serviceHelper.postHelper(
      target: '/v1/wallet/gifts/send',
      token: token,
      data: {
        'receiverId': widget.userId,
        'giftId': gift.id,
        'context': 'profile',
      },
    );

    if (!context.mounted) return;

    if (response is Failure) {
      final message = response.errorResponse?.toString().isNotEmpty == true
          ? response.errorResponse.toString()
          : 'Failed to send gift';
      ToastHelper.showErrorToast(message: message);
      return;
    }

    ToastHelper.showSuccessToast(
      message: '🎁 Gift sent to ${widget.userName}!',
    );
  }
}
