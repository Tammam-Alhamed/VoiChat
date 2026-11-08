import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/helpers/toast_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/utils/api_status.dart';
import '../../app/di/injection_container.dart';
import '../../core/themes/app_dark_colors.dart';
import 'block/blocked_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool hideCountry = false;
  bool lastSeen = false;
  bool totalSpend = false;

  bool _isLoading = true;
  // Prevents a toggle tap while a previous save is still in flight.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/users/me',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            hideCountry = data['hide_country'] == true;
            lastSeen = data['hide_last_seen'] == true;
            totalSpend = data['hide_total_spend'] == true;
          });
        }
      }
    } catch (_) {
      // Keep the defaults (all off) if the fetch fails.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting({
    bool? hideCountryValue,
    bool? hideLastSeenValue,
    bool? hideTotalSpendValue,
  }) async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.putHelper(
        target: '/v1/users/privacy',
        token: token,
        body: {
          if (hideCountryValue != null) 'hideCountry': hideCountryValue,
          if (hideLastSeenValue != null) 'hideLastSeen': hideLastSeenValue,
          if (hideTotalSpendValue != null)
            'hideTotalSpend': hideTotalSpendValue,
        },
      );

      if (response is Failure) {
        ToastHelper.showErrorToast(message: 'Failed to save privacy setting');
        return;
      }

      ToastHelper.showSuccessToast(message: "privacy_settings_updated".tr);
    } catch (_) {
      ToastHelper.showErrorToast(message: 'Failed to save privacy setting');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: context.shellTextPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "privacy".tr,
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Hide Country
              settingSwitch(
                title: "hide_country".tr,
                subtitle: "hide_country_desc".tr,
                value: hideCountry,
                onChanged: (v) {
                  setState(() => hideCountry = v);
                  _saveSetting(hideCountryValue: v);
                },
              ),

              const SizedBox(height: 25),

              /// Last Seen
              settingSwitch(
                title: "last_time_seen".tr,
                subtitle: "last_seen_desc".tr,
                value: lastSeen,
                onChanged: (v) {
                  setState(() => lastSeen = v);
                  _saveSetting(hideLastSeenValue: v);
                },
              ),

              const SizedBox(height: 25),

              /// Total Spend
              settingSwitch(
                title: "total_spend".tr,
                subtitle: "total_spend_desc".tr,
                value: totalSpend,
                onChanged: (v) {
                  setState(() => totalSpend = v);
                  _saveSetting(hideTotalSpendValue: v);
                },
              ),

              const SizedBox(height: 35),

              /// Other
              Text(
                "other".tr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
              ),

              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "blocked_users".tr,
                  style: const TextStyle(fontSize: 20),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.to(const BlockedUsersScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 20)),
            Switch(
              value: value,
              activeTrackColor: const Color(0xFF7B13E2),
              inactiveTrackColor: const Color(0xFFE3E3E3),
              thumbColor: WidgetStateProperty.all(Colors.white),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
        ),
      ],
    );
  }
}
