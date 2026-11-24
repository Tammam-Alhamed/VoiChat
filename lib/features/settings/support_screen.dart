import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/themes/app_dark_colors.dart';
import '../../core/widgets/settings_app_bar.dart';
import '../../core/widgets/settings_widgets.dart';
import 'chat_with_support.dart';
import 'faq_screen.dart';

/// The two support destinations shown from Account Center.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: SettingsAppBar(title: 'support'.tr),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: SettingsMetrics.pagePadding,
          vertical: 20,
        ),
        children: [
          SettingsSectionHeader(title: 'support_info'.tr),
          const SizedBox(height: 12),
          SettingsRow(
            leadingIcon: Icons.help_outline,
            title: 'help_faq'.tr,
            subtitle: 'help_faq_description'.tr,
            trailing: const SettingsChevron(),
            titleStyle: TextStyle(
              fontSize: 18,
              color: context.shellTextPrimary,
            ),
            onTap: () => Get.to(() => const FaqScreen(), duration: const Duration(milliseconds: 400)),
          ),
          const SizedBox(height: 24),
          SettingsRow(
            leadingIcon: Icons.headset_mic_outlined,
            title: 'support_chat'.tr,
            subtitle: 'support_chat_description'.tr,
            trailing: const SettingsChevron(),
            titleStyle: TextStyle(
              fontSize: 18,
              color: context.shellTextPrimary,
            ),
            onTap: () => Get.to(() => const SupportChatScreen()),
          ),
        ],
      ),
    );
  }
}
