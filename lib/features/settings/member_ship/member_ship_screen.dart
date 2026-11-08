import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../show_next_dialog.dart';
import '../../../core/themes/app_dark_colors.dart';

class SVIPMembershipScreen extends StatelessWidget {
  const SVIPMembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // App Bar - Back Button

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 15.h),
                        // SVIP Crown Logo
                        SizedBox(
                          width: 120.w,
                          child: Image.asset(
                            "assets/icons/svip_logo.png", // التاج الذهبي
                            fit: BoxFit.contain,
                          ),
                        ),

                        // SVIP Membership Title
                        Text(
                          "SVIP",
                          style: TextStyle(
                            color: const Color(0xFFD6A22B),
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          "Membership",
                          style: TextStyle(
                            color: const Color(0xFFD6A22B),
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Price Pill Button
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 10.h,
                            horizontal: 45.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFF5A5), Color(0xFFEFBE3B)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Text(
                            "\$29.99 / Month",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        SizedBox(height: 35.h),

                        // Features list
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/svip_crown_badge.png",
                          title: "SVIP Crown Badge",
                          description:
                              "A distinct royal badge displayed beside your name.",
                        ),
                        SizedBox(height: 28.h),
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/unlimited_messages.png",
                          title: "Unlimited Private Messages",
                          description:
                              "Send private messages freely without limits.",
                        ),
                        SizedBox(height: 28.h),
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/monthly_coins.png",
                          title: "Monthly Coins Bonus",
                          description: "Receive 1,500 bonus coins every month.",
                        ),
                        SizedBox(height: 28.h),
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/exclusive_gifts.png",
                          title: "Exclusive Gifts Access",
                          description:
                              "Unlock premium gifts exclusive to SVIP members.",
                        ),
                        SizedBox(height: 28.h),
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/privacy_mode.png",
                          title: "Privacy Mode",
                          description:
                              "Control which details appear on your profile.",
                        ),
                        SizedBox(height: 28.h),
                        _buildFeatureRow(
                          context,
                          iconPath: "assets/icons/priority_support.png",
                          title: "Priority Support",
                          description: "Faster response times",
                        ),

                        // Bottom padding so the last feature row never sits
                        // behind the sticky "Upgrade to SVIP" bar below.
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10.w,
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: context.shellTextPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky/fixed subscribe bar — stays pinned to the bottom regardless
      // of scroll position; only the content above scrolls.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          child: GestureDetector(
            onTap: () => showPaymentGateAlert(),
            child: Container(
              width: double.infinity,
              height: 58.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7247EF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                "Upgrade to SVIP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required String iconPath,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(iconPath, width: 42.w, height: 42.w, fit: BoxFit.contain),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.shellTextPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF7A7A7A),
                  fontSize: 12.sp,
                  height: 1.3, // لتحقيق تباعد الأسطر مثل التصميم
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
