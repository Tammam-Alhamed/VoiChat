import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/helpers/toast_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/utils/api_status.dart';
import '../../app/di/injection_container.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/widgets/settings_app_bar.dart';
import '../../core/widgets/settings_widgets.dart';
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
      appBar: SettingsAppBar(
        title: "privacy".tr,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SettingsMetrics.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

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

            const SizedBox(height: 25),

            /// Other
            SettingsSectionHeader(title: "other".tr),
            const SizedBox(height: 6),

            SettingsRow(
              title: "blocked_users".tr,
              trailing: const SettingsChevron(),
              onTap: () {
                Get.to(const BlockedUsersScreen());
              },
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SettingsMetrics.rowVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: SettingsMetrics.rowTitleSize,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: SettingsMetrics.rowSubtitleSize,
                    color: SettingsMetrics.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SettingsMetrics.iconTextGap),
          SettingsSwitch(value: value, onChanged: (v) => onChanged(v)),
        ],
      ),
    );
  }
}
