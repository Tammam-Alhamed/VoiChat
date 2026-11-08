import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/features/calls/state/calls_provider.dart';
import '../../../../core/themes/app_dark_colors.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/helpers/avatar_helper.dart';
import '../../../profile/profile_screen.dart';
import '../../domain/entities/call_history.dart';

import '../../../session/domain/entities/session_data.dart';

class RecentCallsListItem extends StatelessWidget {
  final CallHistory call;
  final int index;
  final SessionData splashResponse;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapToggle;

  const RecentCallsListItem({
    super.key,
    required this.call,
    required this.index,
    required this.splashResponse,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTapToggle,
  });

  /// Messaging-app-style compact date/time, from closest to farthest:
  ///   Today            -> "12:57 PM"
  ///   This week        -> "Monday • 2:28 PM"
  ///   Older, same year -> "Jul 8 • 2:28 PM"
  ///   Different year   -> "Jul 8, 2025"
  String formatCallDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    final daysDiff = today.difference(inputDate).inDays;

    final time = DateFormat('h:mm a').format(date);

    if (daysDiff == 0) {
      return time;
    }

    if (daysDiff > 0 && daysDiff < 7) {
      return "${DateFormat('EEEE').format(date)} • $time";
    }

    if (date.year == now.year) {
      return "${DateFormat('MMM d').format(date)} • $time";
    }

    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = splashResponse.user?.id;
    final user = currentUserId != call.callerId ? call.caller : call.receiver;
    final name = user.name;
    final avatar = user.profileImage ?? '';
    final subtitle = formatCallDate(call.createdAt);

    final audioIcon = call.status.toLowerCase().contains('missed')
        ? currentUserId != call.callerId
              ? "assets/icons/audio_call_missed_rejected.png"
              : "assets/icons/audio_call_missed_outgoing.png"
        : currentUserId == call.callerId
        ? "assets/icons/audio_call_accepted_outcoming.png"
        : "assets/icons/audio_call_accepted_incoming.png";
    const videoIcon = "assets/icons/call_video.png";

    final durationString = call.duration > 0 ? "${call.duration}s" : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: double.infinity,
      // No horizontal margin/border-radius: the highlight color must
      // reach both screen edges, and stay square so two selected rows
      // stacked back to back paint as one unbroken block with no seam.
      padding: const EdgeInsets.only(left: 21, right: 21, top: 12, bottom: 12),
      color: isSelected
          ? MainColors.primary.withOpacity(0.1)
          : Colors.transparent,
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: isSelectionMode ? onTapToggle : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isSelectionMode
                        ? onTapToggle
                        : () {
                            Get.to(
                              () => TargetProfileScreen(
                                userId: user.id,
                                userName: name,
                                userImage: avatar,
                                index: index,
                              ),
                            );
                          },
                    child: Hero(
                      tag: 'profile_avatar_${name}_$index',
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundColor: context.shellAvatarPlaceholder,
                            radius: 24,
                            backgroundImage: AvatarHelper.resolve(avatar),
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: MainColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 21),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'profile_name_${name}_$index',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: context.shellTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.themedColor(
                            Colors.black54,
                            AppDarkColors.textSecondary,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (durationString != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      durationString == null
                          ? ""
                          : formatDuration(
                              int.parse(
                                durationString.toString().replaceAll('s', ''),
                              ),
                            ),
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Hidden in selection mode so a stray tap can't place a call
                // while the user is picking rows to delete.
                if (!isSelectionMode) ...[
                  _AnimatedIconButton(
                    imagePath: audioIcon,
                    call: call,
                    name: name,
                    id: user.id,
                    avatar: avatar,
                  ),
                  const SizedBox(width: 10),
                  _AnimatedIconButton(
                    imagePath: videoIcon,
                    call: call,
                    id: user.id,
                    name: user.name,
                    avatar: avatar,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final String imagePath;
  final CallHistory call;
  final String id;
  final String name;
  final String avatar;

  const _AnimatedIconButton({
    required this.imagePath,
    required this.id,
    required this.call,
    required this.name,
    required this.avatar,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
        context.read<CallsProvider>().initiateCall(
          receiverId: widget.id,
          receiverName: widget.name,
          receiverImage: widget.avatar,
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.2),
            child: child,
          );
        },
        child: Image.asset(widget.imagePath, width: 24, height: 24),
      ),
    );
  }
}
