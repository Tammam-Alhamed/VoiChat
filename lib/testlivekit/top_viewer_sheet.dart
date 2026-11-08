import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';

import '../features/session/presentation/controllers/session_controller.dart';

void showTopViewersBottomSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> viewers,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // Required for rounded corners + blur
    isScrollControlled: true, // Allows us to control the exact height
    builder: (context) {
      return TopViewersSheet(viewers: viewers);
    },
  );
}

class TopViewersSheet extends StatelessWidget {
  final List<Map<String, dynamic>> viewers;

  const TopViewersSheet({super.key, required this.viewers});

  /// Maps whatever the backend sends in `vip_member` to a display badge.
  /// Adjust this if your `vip_member` values are different
  /// (e.g. it might be a string like "vip"/"svip" instead of an int tier).
  String? _badgeFor(dynamic vipMember) {
    if (vipMember == null || vipMember == false || vipMember == 0) {
      return null;
    }
    if (vipMember is String) {
      final v = vipMember.toLowerCase();
      if (v.contains('svip')) return 'SVIP';
      if (v.contains('vip')) return 'VIP';
      return null;
    }
    if (vipMember is int) {
      if (vipMember >= 2) return 'SVIP';
      if (vipMember == 1) return 'VIP';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionController>(
      builder: (_) => _buildSessionScope(context),
    );
  }

  Widget _buildSessionScope(BuildContext context) {
    final currentUser = Get.find<SessionController>().session!.user!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Top Viewers",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),

          // Scrollable List of Top Viewers
          Expanded(
            child: viewers.isEmpty
                ? const Center(
                    child: Text(
                      "No viewers yet",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: viewers.length,
                    itemBuilder: (context, index) {
                      final viewer = viewers[index];
                      final vip = viewer['vip_member'];
                      return _buildViewerItem(
                        rank: index + 1,
                        name: viewer['name'] ?? 'User',
                        isVerified: viewer['is_verified'] == true,
                        badge: _badgeFor(vip),
                        avatarUrl: viewer['profile_image'],
                      );
                    },
                  ),
          ),

          // Bottom Sticky Section for Current User
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          _buildCurrentUserBottomBar(
            name: currentUser.name ?? 'You',
            avatarUrl: currentUser.profileImage,
          ),
        ],
      ),
    );
  }

  Widget _buildViewerItem({
    required int rank,
    required String name,
    required bool isVerified,
    required String? badge,
    required String? avatarUrl,
  }) {
    final bool isFirst = rank == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: isFirst ? const Color(0xFFFFD700) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            backgroundImage: AvatarHelper.resolve(avatarUrl),
          ),
          const SizedBox(width: 12),

          // Name and Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isFirst
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF8B3EE8),
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  badge == "SVIP"
                      ? SvgPicture.asset(AssetsManager.svip)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff7247EF), Color(0xffB862E1)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sticky bottom bar for the active user
  Widget _buildCurrentUserBottomBar({required String name, String? avatarUrl}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            child: Text(
              "-", // Unranked
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            backgroundImage: AvatarHelper.resolve(avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Send a gift to be a top viewer",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),

          // Send Gift Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xff7247EF), Color(0xffB862E1)],
              ),
            ),
            child: const Text(
              "Send Gift",
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
