import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'otp_screen.dart';

import '../widgets/footer_widget.dart';

import '../controllers/auth_controller.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  String? _errorMessage;

  // Pure code-level guard against double-submit while a request is in
  // flight — intentionally NOT tied to any loading spinner or disabled
  // state on the button, per request. The button always looks the same;
  // extra taps while `_isSubmitting` is true are just ignored.
  bool _isSubmitting = false;

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    final email = _emailController.text.trim();

    // Clear old error
    setState(() {
      _errorMessage = null;
    });

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      setState(() {
        _errorMessage = 'enter_valid_email_address'.tr;
      });
      _isSubmitting = false;
      return;
    }

    final authProvider = Get.find<AuthController>();
    final result = await authProvider.loginWithEmail(email);

    final requiresOtp = result.requiresOtp;
    final notRegistered = result.notRegistered;

    if (requiresOtp) {
      Get.to(() => OTPScreen(contactInfo: email, isEmail: true));
    } else if (notRegistered) {
      setState(() {
        _errorMessage = 'email_not_registered_please_use_google'.tr;
      });
    } else if (authProvider.errorMessage != null) {
      setState(() {
        _errorMessage = authProvider.errorMessage!;
      });
    }

    _isSubmitting = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                  'enter_your_email'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                Text(
                  'email_otp_subtitle'.tr,
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),

                SizedBox(height: 40.h),
                SizedBox(height: 60.h),

                // Email field + error
                Container(
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: _errorMessage != null
                          ? Colors.red
                          : const Color(0xFF31266A),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'email_address'.tr,
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 15.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 18.h,
                      ),
                    ),
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 20.h),

                // Continue button — always looks the same; double-submit is
                // guarded purely in code via `_isSubmitting` in
                // `_handleLogin()`, not via a loading/disabled UI state.
                GestureDetector(
                  onTap: _handleLogin,
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
                    child: Text(
                      'continue'.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
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
}
