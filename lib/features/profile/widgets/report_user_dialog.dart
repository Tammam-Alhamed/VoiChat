import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../data/report_user_enum.dart';
import '../state/target_profile_provider.dart'; // Make sure the provider path is correct
import '../../../core/themes/app_dark_colors.dart';

class ReportUserDialog extends StatelessWidget {
  final String userId;
  final String userName;

  ReportUserDialog({super.key, required this.userId, required this.userName});

  // Using Enum as default value instead of text strings
  final ValueNotifier<ReportReason> selectedReason =
      ValueNotifier<ReportReason>(ReportReason.spam);
  final TextEditingController descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.shellSurface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<TargetProfileProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.report_problem_rounded,
                        color: Color(0xFF7247EF),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Report ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.shellTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Main Report Reason:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown using Enum
                  ValueListenableBuilder<ReportReason>(
                    valueListenable: selectedReason,
                    builder: (context, currentReason, child) {
                      return DropdownButtonFormField<ReportReason>(
                        value: currentReason,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.themedColor(
                            const Color(0xFFF9F9F9),
                            AppDarkColors.card,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        // Passing the enum values directly
                        items: ReportReason.values.map((ReportReason reason) {
                          return DropdownMenuItem<ReportReason>(
                            value: reason,
                            child: Row(
                              children: [
                                Icon(
                                  reason.icon,
                                  size: 18,
                                  color: const Color(0xFF555555),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  reason
                                      .title, // Using the title from extension
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.shellTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) selectedReason.value = val;
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Additional Details (Optional):",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          "Write details to help the admin review the account...",
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: context.themedColor(
                              const Color(0xFFEDEDED),
                              AppDarkColors.card,
                            ),
                          ),
                          onPressed: provider.reportLoader
                              ? null
                              : () => Get.back(),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: context.shellTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF7247EF),
                            elevation: 0,
                          ),
                          onPressed: provider.reportLoader
                              ? null
                              : () {
                                  // Passing the string value required by the API directly from the Extension
                                  provider.reportUser(
                                    userId: userId,
                                    userName: userName,
                                    reason: selectedReason
                                        .value
                                        .value, // This returns 'spam', 'harassment', etc.
                                    description: descController.text,
                                  );
                                },
                          child: provider.reportLoader
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Submit Report",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
