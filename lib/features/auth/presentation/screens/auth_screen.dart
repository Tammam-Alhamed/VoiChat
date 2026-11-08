import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoeebapk/features/auth/presentation/widgets/footer_widget.dart';
import 'package:shoeebapk/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:shoeebapk/features/auth/presentation/screens/enter_name_screen.dart';
import 'package:shoeebapk/features/auth/presentation/screens/email_login_screen.dart';
import 'package:shoeebapk/features/auth/presentation/helpers/login_success_handler.dart';
import '../../../../core/helpers/toast_helper.dart';
import '../controllers/auth_controller.dart';
import '../../../session/presentation/controllers/session_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1.sw, // 100% من عرض الشاشة
        height: 1.sh, // 100% من طول الشاشة
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff060912), Color(0xff111032)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 48.h), // مسافة متناسبة طولياً
              // LOGO
              SizedBox(
                width: 210.w, // عرض متناسب
                height: 140.h, // طول متناسب
                child: Image.asset(
                  "assets/images/voichatlogoneno.png",
                  fit: BoxFit.contain, // أفضل للمحافظة على أبعاد اللوغو
                ),
              ),

              SizedBox(height: 10.h),

              /// TITLE
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFFFFF),
                    Color(0xFF190B0B),
                  ],
                ).createShader(bounds),
                child: Text(
                  "VoiChat",
                  style: TextStyle(
                    fontFamily: "ZenDots",
                    fontSize: 32.sp, // خط متناسب
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              Spacer(),

              /// LOGIN TEXT
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 34.w),
                child: Text(
                  "login_to_account".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21.sp, // خط متناسب
                  ),
                ),
              ),

              SizedBox(height: 18.h),

              /// GOOGLE BUTTON
              _buildSocialButton(
                iconPath: "assets/icons/googleauth.png",
                text: "continue_with_google".tr,
                isSvg: false,
                onTap: _handleGoogleLogin,
              ),

              SizedBox(height: 18.h),

              /// PHONE BUTTON
              _buildSocialButton(
                iconPath: "assets/icons/iphoneauth.svg",
                text: "continue_with_phone".tr,
                isSvg: true,
                iconColor: const Color(0xff5B2BB2),
                onTap: () => Get.to(const PhoneLoginScreen()),
              ),

              SizedBox(height: 18.h),

              /// EMAIL BUTTON
              _buildSocialButton(
                iconPath: "assets/icons/email.svg",
                text: "continue_with_email".tr,
                isSvg: true,
                iconColor: const Color(0xff5B2BB2),
                onTap: () {
                  Get.to(() => const EmailLoginScreen());
                },
              ),

              SizedBox(height: 67.h),

              /// TERMS TEXT
              FooterWidget(),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = Get.find<AuthController>();
    final result = await authProvider.loginWithGoogle();

    final success = result.success;
    final isNewUser = result.isNewUser;

    if (success) {
      if (isNewUser) {
        Get.off(() => const YourNameScreen());
      } else if (mounted) {
        await completeLoginAndGoHome(Get.find<SessionController>());
      }
    } else if (authProvider.errorMessage != null) {
      ToastHelper.showErrorToast(message: authProvider.errorMessage!);
    }
  }

  // ويدجت مساعدة لتقليل تكرار الكود وتنظيمه
  Widget _buildSocialButton({
    required String iconPath,
    required String text,
    required bool isSvg,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 315.w,
        margin: EdgeInsets.symmetric(horizontal: 34.w),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSvg ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(35.r),
          border: isSvg ? Border.all(color: const Color(0xFF31266A)) : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 22.w),
            SizedBox(
              width: 28.w,
              height: 28.w,
              child: isSvg
                  ? SvgPicture.asset(
                      iconPath,
                      colorFilter: iconColor != null
                          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                          : null,
                    )
                  : Image.asset(iconPath),
            ),
            SizedBox(width: 32.w),
            Text(
              text,
              style: TextStyle(
                color: isSvg ? const Color(0xFF7A7A7A) : Colors.black,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
