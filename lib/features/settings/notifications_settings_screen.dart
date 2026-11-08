import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/themes/app_dark_colors.dart';
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

  Widget _buildSupportAppBar(BuildContext context) {
    return Padding(
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
            "notifications".tr,
            style: TextStyle(
              color: context.shellTextPrimary,
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,

      body: SafeArea(
        child: Column(
          children: [
            _buildSupportAppBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// Live Stream Section
                  Text(
                    "live_stream".tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        "live_notification".tr,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_outlined, size: 18),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "live_notification_desc".tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Other Section
                  Text(
                    "other".tr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// In-App Sound
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "in_app_sound".tr,
                        style: const TextStyle(fontSize: 20),
                      ),

                      Switch(
                        value: inAppSound,
                        activeTrackColor: const Color(
                          0xFF7B13E2,
                        ), // purple background when ON
                        inactiveTrackColor: const Color(
                          0xFFE3E3E3,
                        ), // gray when OFF
                        thumbColor: WidgetStateProperty.all(
                          Colors.white,
                        ), // white circle
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // remove border

                        onChanged: (value) {
                          setState(() {
                            inAppSound = value;
                          });
                          _storeHelper.setInAppSoundEnabled(value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Vibrations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "in_app_vibrations".tr,
                        style: const TextStyle(fontSize: 20),
                      ),

                      Switch(
                        value: vibrations,
                        activeColor: const Color(0xFF7B13E2),
                        activeTrackColor: const Color(
                          0xFF7B13E2,
                        ), // purple background when ON
                        inactiveTrackColor: const Color(
                          0xFFE3E3E3,
                        ), // gray when OFF
                        thumbColor: WidgetStateProperty.all(
                          Colors.white,
                        ), // white circle
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // remove border

                        onChanged: (value) {
                          setState(() {
                            vibrations = value;
                          });
                          _storeHelper.setVibrationsEnabled(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
