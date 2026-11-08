import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/helpers/toast_helper.dart';
import '../helpers/login_success_handler.dart';
import '../widgets/birthdate_picker_sheet.dart';
import '../../../../core/utils/age_policy.dart';

import '../controllers/auth_controller.dart';
import '../../../session/presentation/controllers/session_controller.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  DateTime? _selectedDate;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  bool get _isUnderage =>
      _selectedDate != null && !AgePolicy.isAdult(_selectedDate!);

  Future<void> _pickDate() async {
    final picked = await showBirthdatePickerSheet(
      context,
      initial: _selectedDate,
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  String get _formattedDate {
    if (_selectedDate == null) return 'enter_your_birthday'.tr;
    return '${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  Future<void> _handleComplete() async {
    final authProvider = Get.find<AuthController>();
    final name = authProvider.pendingName ?? '';

    if (name.isEmpty) {
      ToastHelper.showErrorToast(message: 'go_back_enter_name'.tr);
      return;
    }

    if (_selectedDate == null || _isUnderage) return; // server checks too

    authProvider.setPendingBirthday(_selectedDate!);

    final success = await authProvider.completeProfile(
      name: name,
      birthday: _selectedDate,
    );

    if (success) {
      if (!mounted) return;
      // HomeScreen (and most authenticated screens) assume splashModel is
      // already populated — this is a brand-new account, so there's nothing
      // cached yet on this device. completeLoginAndGoHome() fetches it once
      // (or reuses the cache) before navigating, so we never hand off to a
      // screen that force-unwraps a null splashModel.
      await completeLoginAndGoHome(Get.find<SessionController>());
    } else {
      ToastHelper.showErrorToast(
        message: authProvider.errorMessage ?? 'failed_to_complete_profile'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff060912), Color(0xff111032)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  'birthday'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'select_your_birthdate'.tr,
                  style: TextStyle(color: Colors.white70, fontSize: 18.sp),
                ),
                SizedBox(height: 40.h),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    height: 55.h,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color: _isUnderage
                            ? const Color(0xFFFF4D4F)
                            : const Color(0xFF31266A),
                      ),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formattedDate,
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.white38
                            : Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                if (_isUnderage)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h, left: 12.w),
                    child: Text(
                      AgePolicy.underageMessage,
                      style: TextStyle(
                        color: const Color(0xFFFF4D4F),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_selectedDate != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: GetBuilder<AuthController>(
                      builder: (auth) {
                        final isLoading = auth.isLoading;
                        // Grey + disabled while the date is under 18.
                        return _buildContinueButton(
                          isEnabled: !isLoading && !_isUnderage,
                          isLoading: isLoading,
                          onTap: _handleComplete,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton({
    required bool isEnabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 55.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          gradient: LinearGradient(
            colors: (isEnabled || isLoading)
                ? [const Color(0xFF7247EF), const Color(0xFFB862E1)]
                : [const Color(0xFF4A4A5C), const Color(0xFF4A4A5C)],
          ),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'continue'.tr,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.white54,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
