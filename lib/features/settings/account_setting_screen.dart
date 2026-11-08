import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/extentions.dart';
import 'package:shoeebapk/core/themes/app_dark_colors.dart';
import 'package:shoeebapk/features/settings/state/account_setting_provider.dart';

import '../../core/helpers/toast_helper.dart';
import '../../core/localization/localization_service.dart';
import 'linked_device_screen.dart';
import 'widget/contact_verify_sheet.dart';

import '../session/presentation/controllers/session_controller.dart';

class AccountSettingScreen extends StatelessWidget {
  const AccountSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionController>(
      builder: (_) => _buildSessionScope(context),
    );
  }

  Widget _buildSessionScope(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: AppBar(
        backgroundColor: context.shellBackground,
        elevation: 0,
        foregroundColor: context.shellTextPrimary,
        leading: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.arrow_back_ios_new),
          ),
        ),
        title: Text(
          "account".tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 10),

          /// Personal Info
          Text(
            "personal_info".tr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
          ),
          const SizedBox(height: 10),

          // --- Phone Number Section ---
          Get.find<SessionController>().session!.user!.phone != null
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone),
                  title: Text("phone_number".tr),
                  subtitle: Text(
                    Get.find<SessionController>().session!.user!.phone!,
                  ).fs12,
                  onTap: () => showUpdateFieldSheet(context, isPhone: true),
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone),
                  title: Text("phone_number".tr),
                  trailing: const Icon(Icons.add),
                  onTap: () => showUpdateFieldSheet(context, isPhone: true),
                ),

          // --- Email/Google Section ---
          Get.find<SessionController>().session!.user!.email != null
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_outline),
                  title: const Text("Google"), // brand name — not translated
                  subtitle: Text(
                    Get.find<SessionController>().session!.user!.email!,
                  ),
                  // The account's email can't be changed.
                  trailing: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Color(0xFF7A7A7A),
                  ),
                  onTap: () => ToastHelper.showInfoToast(
                    message: "Your account's email can't be changed",
                  ),
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_outline),
                  title: const Text("Google"), // brand name — not translated
                  trailing: const Icon(Icons.add),
                  onTap: () => showUpdateFieldSheet(context, isPhone: false),
                ),
          const SizedBox(height: 20),

          /// Other
          Text(
            "other".tr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
          ),
          const SizedBox(height: 10),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("join_an_agency".tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (Get.find<SessionController>()
                      .session!
                      .user!
                      .referredByProfileId !=
                  null) {
                ToastHelper.showInfoToast(message: "already_in_agency".tr);
                return;
              }
              showJoinAgencySheet(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "${"linked_device".tr} "
              "(${Get.find<SessionController>().session!.userDevices.length})",
            ),
            subtitle: Text(
              "see_all_devices_desc".tr,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.to(const LinkedDeviceScreen());
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("language_settings".tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageDialog(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("delete_account".tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDeleteAccountSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // --- Change phone / add email (confirmed with a one-time code) ---
  void showUpdateFieldSheet(BuildContext context, {required bool isPhone}) {
    final accountProvider = context.read<AccountSettingProvider>();
    if (accountProvider.isUpdating) {
      ToastHelper.showInfoToast(message: "update_in_progress".tr);
      return;
    }
    final currentUser = Get.find<SessionController>().session!.user!;
    if (!isPhone && currentUser.email != null) {
      ToastHelper.showInfoToast(
        message: "Your account's email can't be changed",
      );
      return;
    }
    ContactVerifySheet.show(
      context,
      isPhone: isPhone,
      initialValue: isPhone ? currentUser.phone : null,
    );
  }

  void showJoinAgencySheet(BuildContext context) {
    final TextEditingController agencyController = TextEditingController();
    final accountProvider = context.read<AccountSettingProvider>();

    if (accountProvider.isUpdating) {
      ToastHelper.showInfoToast(message: "Operation in progress...");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: 420,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "enter_referral_code".tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "referral_code_desc".tr,
                style: const TextStyle(fontSize: 16, fontFamily: 'Open Sans'),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: agencyController,
                decoration: InputDecoration(
                  hintText: "enter_code".tr,
                  hintStyle: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF7247EF)),
                  ),
                ),
              ),
              const Spacer(),
              Consumer<AccountSettingProvider>(
                builder: (context, provider, _) {
                  final bool loading = provider.isUpdating;
                  return SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final String code = agencyController.text.trim();
                              if (code.isEmpty) {
                                ToastHelper.showErrorToast(
                                  message: "enter_valid_referral_code".tr,
                                );
                                return;
                              }

                              final bool success = await accountProvider
                                  .joinAgency(agentId: code);

                              if (success && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: loading
                                ? [Colors.grey.shade400, Colors.grey.shade300]
                                : const [Color(0xFF7247EF), Color(0xFFB862E1)],
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  "join_agency".tr,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ).then((_) {
      // Dispose only after the sheet has fully closed.
      agencyController.dispose();
    });
  }

  void showDeleteAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                "delete_this_account".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "delete_account_desc".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontFamily: 'Open Sans'),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${"all_word".tr} ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: "personal_data".tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                        color: Color(0xFF7B13E2),
                      ),
                    ),
                    TextSpan(
                      text: " ${"will_be_removed".tr}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement delete account functionality
                    Navigator.pop(context);
                    ToastHelper.showInfoToast(
                      message: "delete_account_coming_soon".tr,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Center(
                      child: Text(
                        "confirm_account_deletion".tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBBBBBB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    "cancel".tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Language Selection Dialog ---
  void showLanguageDialog(BuildContext context) {
    final localizationService = LocalizationService();
    // The 6 languages the app ships with — single source of truth is
    // LocalizationService, so this list can never drift out of sync with
    // what's actually registered in GetMaterialApp.
    final List<String> languages = LocalizationService.languages;
    String selectedLanguage = localizationService.getLanguage();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "select_language".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "choose_preferred_language".tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Open Sans',
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: languages.length,
                        itemBuilder: (context, index) {
                          final langName = languages[index];
                          final bool isSelected = langName == selectedLanguage;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              value: langName,
                              groupValue: selectedLanguage,
                              activeColor: const Color(0xFF7247EF),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                langName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Open Sans',
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => selectedLanguage = value!);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFBBBBBB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Text(
                                "cancel".tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);

                                // Actually persist + apply the locale, then
                                // rebuild the whole app tree via GetX so
                                // every already-built `.tr` string picks up
                                // the new language immediately.
                                localizationService.changeLanguage(
                                  selectedLanguage,
                                );

                                ToastHelper.showInfoToast(
                                  message: "language_set_to".trParams({
                                    'language': selectedLanguage,
                                  }),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Ink(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF7247EF),
                                      Color(0xFFB862E1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "apply".tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Open Sans',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
