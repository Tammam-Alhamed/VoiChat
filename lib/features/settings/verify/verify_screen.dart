import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../show_next_dialog.dart';
import '../../../core/themes/app_dark_colors.dart';

class VerifiedAccountScreen extends StatefulWidget {
  const VerifiedAccountScreen({super.key});

  @override
  State<VerifiedAccountScreen> createState() => _VerifiedAccountScreenState();
}

class _VerifiedAccountScreenState extends State<VerifiedAccountScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar - Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: context.shellTextPrimary,
                    size: 28.sp,
                  ),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10.h),

                    // Main Purple Verified Icon with Shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B13E2).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        "assets/icons/verified_main.png",
                        width: 100.w,
                        height: 100.w,

                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Titles
                    Text(
                      "Purple Verified+",
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "999 Coins /Month",
                      style: TextStyle(
                        color: const Color(0xFF7B13E2),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Upgrade Status Button

                    // Section Title
                    Text(
                      "Verified Account Details",
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Features List
                    _buildFeatureItem(
                      iconPath: "assets/icons/protection_layer.png",
                      title: "Identity Verification",
                      subtitle: "Your account is officially verified",
                    ),
                    SizedBox(height: 30.h),
                    _buildFeatureItem(
                      iconPath: "assets/icons/priority_assistance.png",
                      title: "Protection Layer",
                      subtitle: "Extra safety against impersonation",
                    ),
                    SizedBox(height: 30.h),
                    _buildFeatureItem(
                      iconPath: "assets/icons/service.png",
                      title: "Priority Assistance",
                      subtitle: "Direct access to VIP support",
                    ),
                    SizedBox(height: 30.h),
                    _buildFeatureItem(
                      iconPath: "assets/icons/trusted_visibility.png",
                      title: "Trusted Visibility",
                      subtitle: "Higher credibility in the community",
                    ),
                    // Bottom padding so the last feature row never sits
                    // behind the sticky "Upgrade Status" bar below.
                    SizedBox(height: 24.h),
                  ],
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
                borderRadius: BorderRadius.circular(30.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB862E1), Color(0xFF7247EF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7247EF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                "Upgrade Status",
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

  Widget _buildFeatureItem({
    required String iconPath,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon Container
        Container(
          width: 45.w,
          height: 45.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FF),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.all(10.w),
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.verified_user,
              color: const Color(0xFF7B13E2),
              size: 20.sp,
            ),
          ),
        ),
        SizedBox(width: 18.w),
        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.shellTextPrimary,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF7A7A7A),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
