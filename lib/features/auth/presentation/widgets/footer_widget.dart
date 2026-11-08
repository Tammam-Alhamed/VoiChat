import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w),
        child: Column(
          children: [
            Text(
              "footer_age_confirm".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF7E7E7E)),
            ),
            SizedBox(height: 7.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: const Color(0xFF7E7E7E),
                  fontSize: 12.sp,
                ),
                children: [
                  TextSpan(text: "${'to_our'.tr} "),
                  TextSpan(
                    text: "terms_of_use".tr,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color.fromARGB(255, 158, 158, 158),
                    ),
                  ),
                  TextSpan(text: " ${'and_conjunction'.tr} "),
                  TextSpan(
                    text: "privacy_policy".tr,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Color.fromARGB(255, 158, 158, 158),
                    ),
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
