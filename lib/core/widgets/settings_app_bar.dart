import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/widgets/settings_widgets.dart';

import '../themes/app_dark_colors.dart';

/// The standard top bar for every sub-screen (Account, Notifications,
/// Privacy, Linked Devices...). One widget so the back-arrow-to-title gap,
/// horizontal padding and title typography are identical everywhere.
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(

      backgroundColor: context.shellBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: context.shellTextPrimary,
      // Tight leading slot -> the arrow sits close to the title.
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 4,
      actions: actions,
      bottom: bottom,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: "ProximaNova",
          color: context.shellTextPrimary,
          fontSize: SettingsMetrics.screenTitleSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
