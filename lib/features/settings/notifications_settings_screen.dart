import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/widgets/settings_app_bar.dart';
import '../../core/widgets/settings_widgets.dart';
import '../../app/di/injection_container.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _Done62State();
}

class _Done62State extends State<NotificationsSettingsScreen> {
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool inAppSound = false;
  bool vibrations = false;

  @override
  void initState() {
    super.initState();
    inAppSound = _storeHelper.getInAppSoundEnabled();
    vibrations = _storeHelper.getVibrationsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: SettingsAppBar(title: "notifications".tr),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SettingsMetrics.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// Live Stream Section
            SettingsSectionHeader(title: "live_stream".tr),
            const SizedBox(height: 6),

            SettingsRow(
              title: "live_notification".tr,
              subtitle: "live_notification_desc".tr,
              trailing: const SettingsChevron(),
            ),

            const SizedBox(height: 25),

            /// Other Section
            SettingsSectionHeader(title: "other".tr),
            const SizedBox(height: 6),

            /// In-App Sound
            _settingSwitchRow(
              title: "in_app_sound".tr,
              value: inAppSound,
              onChanged: (value) {
                setState(() {
                  inAppSound = value;
                });
                _storeHelper.setInAppSoundEnabled(value);
              },
            ),

            /// Vibrations
            _settingSwitchRow(
              title: "in_app_vibrations".tr,
              value: vibrations,
              onChanged: (value) {
                setState(() {
                  vibrations = value;
                });
                _storeHelper.setVibrationsEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SettingsMetrics.rowVerticalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: SettingsMetrics.rowTitleSize,
              ),
            ),
          ),
          const SizedBox(width: SettingsMetrics.iconTextGap),
          SettingsSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
