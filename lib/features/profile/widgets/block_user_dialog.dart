import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../state/target_profile_provider.dart'; // Adjust the path according to your project
import '../../../core/themes/app_dark_colors.dart';

class BlockUserDialog extends StatelessWidget {
  final String userId;
  final String userName;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.shellSurface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<TargetProfileProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Color(0xFFFF3C1F),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "block_user_title".trParams({"name": userName}),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.shellTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "block_user_warning".tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7A7A7A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
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
                        onPressed: provider.blockLoader
                            ? null
                            : () => Get.back(),
                        child: Text(
                          "cancel".tr,
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
                          backgroundColor: const Color(0xFFFF3C1F),
                          elevation: 0,
                        ),
                        onPressed: provider.blockLoader
                            ? null
                            : () => provider.blockUser(
                                userId: userId,
                                userName: userName,
                              ),
                        child: provider.blockLoader
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "confirm_block".tr,
                                style: const TextStyle(
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
    );
  }
}
