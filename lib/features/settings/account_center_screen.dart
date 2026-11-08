import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:shoeebapk/core/themes/app_dark_colors.dart';
import 'package:shoeebapk/features/settings/chat_with_support.dart';
import 'package:shoeebapk/features/settings/notifications_settings_screen.dart';
import 'package:shoeebapk/features/settings/payout/payout_screen.dart';

import 'account_setting_screen.dart';
import 'creators/creators_screen.dart';
import 'edit_profile_screen.dart';
import 'invate_link_screen.dart';
import 'member_ship/member_ship_screen.dart';
import 'performance_screen.dart';
import 'privacy_screen.dart';
import 'rate/call_ratings.dart';
import 'recharge/recharge_screen.dart';
import 'theme_screen.dart';
import 'verify/verify_screen.dart';
import 'widget/logout_sheet.dart';

class AccountCenterScreen extends StatefulWidget {
  const AccountCenterScreen({super.key});

  @override
  State<AccountCenterScreen> createState() => _AccountCenterScreenState();
}

// 🔥 ADDED: SingleTickerProviderStateMixin for the AnimationController
class _AccountCenterScreenState extends State<AccountCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // The total duration for the entire wave of animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Adjusted for ~15 items
    );

    // Start the animation as soon as the screen opens
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==========================================
  // 🔥 THE MAGIC: Staggered Right-to-Left Animation
  // ==========================================
  Widget _buildAnimatedItem(Widget child, int index) {
    // Each item starts slightly later than the previous one (index * 0.04)
    double start = (index * 0.04).clamp(0.0, 1.0);
    double end = (start + 0.4).clamp(0.0, 1.0);

    final Animation<double> animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            // Slides from Right (50 pixels) to Left (0) smoothly
            offset: Offset(50 * (1 - animation.value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Store all settings items in a list so we can map over them dynamically
    final List<Widget> settingsItems = [
      // Profile
      _buildSectionHeader('profile'.tr),
      _buildSettingsItem(
        icon: Icons.person_outline,
        title: 'edit_profile'.tr,
        onTap: () => Get.to(
          EditProfileScreen(),
        ),
      ),

      // Exclusive Features
      _buildSectionHeader('exclusive_features'.tr),
      _buildSettingsItem(
        icon: Icons.star_border,
        title: 'vip_membership'.tr,
        onTap: () => Get.to(
          SVIPMembershipScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.verified_outlined,
        title: 'verified_plus'.tr,
        onTap: () => Get.to(
          VerifiedAccountScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.account_balance_wallet_outlined,
        title: 'recharge_center'.tr,
        onTap: () => Get.to(
          RechargeCenterScreen(),
        ),
      ),

      // Creator Hub
      _buildSectionHeader('creator_hub'.tr),
      _buildSettingsItem(
        icon: Icons.bar_chart_outlined,
        title: 'performance'.tr,
        onTap: () => Get.to(
          PerformanceScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.payment_outlined,
        title: 'payout'.tr,
        onTap: () => Get.to(
          PayoutScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.star_rate_outlined,
        title: 'call_rating'.tr,
        onTap: () => Get.to(
          CallRatingScreen(),
        ),
      ),

      // Partner Hub
      _buildSectionHeader('partner_hub'.tr),
      _buildSettingsItem(
        icon: Icons.group_outlined,
        title: 'manage_creators'.tr,
        onTap: () => Get.to(
          ManageCreatorsScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.link_outlined,
        title: 'invite_link'.tr,
        onTap: () => Get.to(
          InviteLinkScreen(),
        ),
      ),

      // Settings
      _buildSectionHeader('settings'.tr),
      _buildSettingsItem(
        icon: Icons.manage_accounts_outlined,
        title: 'account'.tr,
        onTap: () => Get.to(
          AccountSettingScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.notifications_none_outlined,
        title: 'notifications'.tr,
        onTap: () => Get.to(
          NotificationsSettingsScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.lock_outline,
        title: 'privacy'.tr,
        onTap: () => Get.to(
          PrivacyScreen(),
        ),
      ),
      _buildSettingsItem(
        icon: Icons.display_settings_outlined,
        title: 'display'.tr,
        onTap: () => Get.to(
          ThemeScreen(),
        ),
      ),

      // Support
      _buildSectionHeader('support'.tr),
      _buildSettingsItem(
        icon: Icons.headset_mic_outlined,
        title: 'support_chat'.tr,
        onTap: () => Get.to(
          SupportChatScreen(),
        ),
      ),

      // Logins
      _buildSectionHeader('logins'.tr),
      _buildSettingsItem(
        icon: Icons.logout_outlined,
        title: 'logout'.tr,
        titleColor: Colors.red,
        iconColor: Colors.red,
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => const LogOutBottomSheet(),
          );
        },
      ),

      const SizedBox(height: 40),

      // Footer
      Center(
        child: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            children: [
              TextSpan(
                text: 'app_footer_version'.tr,
                style: const TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'privacy_policy'.tr,
                style: const TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(
                text: '  ·  ',
                style: TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'terms_and_conditions'.tr,
                style: const TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 30),
    ];

    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Static Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: context.shellTextPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'account_center'.tr,
                    style: TextStyle(
                      color: context.shellTextPrimary,
                      fontSize: 22,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.02,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Animated Scrollable Settings List
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Premium bounce effect
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // 🔥 We map through our items and apply the staggered animation
                    children: settingsItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      Widget item = entry.value;
                      return _buildAnimatedItem(item, index);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Section Header
  // ==========================================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF7A7A7A),
          fontSize: 12,
          fontFamily: 'SF Pro',
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ==========================================
  // Settings Item Row
  // ==========================================
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor ?? context.shellTextPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? context.shellTextPrimary,
                    fontSize: 18,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.02,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
