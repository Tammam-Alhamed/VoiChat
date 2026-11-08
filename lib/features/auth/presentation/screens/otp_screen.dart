import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'enter_name_screen.dart';
import '../widgets/footer_widget.dart';
import '../helpers/login_success_handler.dart';

import '../../../../core/helpers/toast_helper.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_outcome.dart';
import '../../../session/presentation/controllers/session_controller.dart';

class OTPScreen extends StatefulWidget {
  final String contactInfo;
  final bool isEmail;

  const OTPScreen({super.key, required this.contactInfo, this.isEmail = false});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  // تعريف Controllers لمراقبة النص في كل مربع
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _isOtpComplete = false;
  Timer? _timer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // إضافة مستمع لكل controller للتأكد من حالة الاكتمال
    for (var controller in _controllers) {
      controller.addListener(_checkOtpStatus);
    }
  }

  void _checkOtpStatus() {
    // التأكد إذا كانت كل المربعات تحتوي على رقم واحد
    bool isAllFilled = _controllers.every((c) => c.text.isNotEmpty);
    if (isAllFilled != _isOtpComplete) {
      setState(() {
        _isOtpComplete = isAllFilled;
      });
    }
  }

  void _startTimer() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;

    final authProvider = Get.find<AuthController>();
    bool success = false;

    if (widget.isEmail) {
      // For email registration, re-triggering login sends the OTP again if user doesn't exist
      final result = await authProvider.loginWithEmail(widget.contactInfo);
      success = result.requiresOtp;
    } else {
      success = await authProvider.sendOtp(widget.contactInfo);
    }

    if (success) {
      _startTimer();
      ToastHelper.showSuccessToast(message: 'code_sent_desc'.tr);
    } else {
      ToastHelper.showErrorToast(
        message: authProvider.errorMessage ?? 'failed_to_resend_code'.tr,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    final authProvider = Get.find<AuthController>();

    AuthOutcome result;
    if (widget.isEmail) {
      result = await authProvider.verifyEmailOtp(widget.contactInfo, otp);
    } else {
      result = await authProvider.verifyOtp(widget.contactInfo, otp);
    }

    final success = result.success;
    final isNewUser = result.isNewUser;

    if (success) {
      if (isNewUser) {
        // New user → go to profile setup (Enter Name)
        Get.off(() => const YourNameScreen());
      } else if (mounted) {
        // Existing user → go straight to home
        await completeLoginAndGoHome(Get.find<SessionController>());
      }
    } else {
      ToastHelper.showErrorToast(
        message: authProvider.errorMessage ?? 'invalid_otp'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  'enter_verification_code'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'code_sent_via'.trParams({
                    'contact': widget.contactInfo,
                    'method': widget.isEmail ? 'email'.tr : 'sms'.tr,
                  }),
                  style: TextStyle(color: Colors.white70, fontSize: 15.sp),
                ),
                SizedBox(height: 40.h),

                // مربعات الـ OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => _buildOTPBox(context, index),
                  ),
                ),

                SizedBox(height: 40.h),

                // عرض الزر فقط إذا اكتمل الـ OTP
                if (_isOtpComplete)
                  GetBuilder<AuthController>(
                    builder: (auth) {
                      final isLoading = auth.isLoading;
                      return GestureDetector(
                        onTap: isLoading ? null : _handleVerifyOtp,
                        child: Container(
                          width: double.infinity,
                          height: 55.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
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
                                  'verify'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                SizedBox(height: 30.h),
                Center(
                  child: GestureDetector(
                    onTap: _countdown == 0 ? _handleResend : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: _countdown == 0
                              ? const Color(0xff7247EF)
                              : const Color(0xff31266A),
                        ),
                        color: _countdown == 0
                            ? const Color(0xff7247EF).withOpacity(0.2)
                            : const Color(0xff31266A).withOpacity(0.2),
                      ),
                      child: Text(
                        _countdown > 0
                            ? 'resend_in'.trParams({
                                'time':
                                    '00:${_countdown.toString().padLeft(2, '0')}',
                              })
                            : 'resend_code'.tr,
                        style: TextStyle(
                          color: _countdown == 0
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 13.sp,
                          fontWeight: _countdown == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (!isKeyboardOpen) FooterWidget(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context, int index) {
    return Container(
      width: 45.w, // reduced width slightly to fit 6 boxes
      height: 55.h, // reduced height slightly
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? const Color(0xFFB862E1)
              : const Color(0xFF31266A),
          width: 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          onChanged: (value) {
            if (value.length == 1 && index < 5) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }
          },
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
