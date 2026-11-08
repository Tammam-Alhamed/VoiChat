import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'birthday_select_screen.dart';

import '../controllers/auth_controller.dart';

class YourNameScreen extends StatefulWidget {
  const YourNameScreen({super.key});

  @override
  State<YourNameScreen> createState() => _YourNameScreenState();
}

class _YourNameScreenState extends State<YourNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() => _isButtonEnabled = _nameController.text.trim().isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            child: SingleChildScrollView(
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
                    'welcome_exclaim'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'enter_name_to_continue'.tr,
                    style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                  ),
                  SizedBox(height: 40.h),
                  Container(
                    height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: const Color(0xFF31266A)),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'name'.tr,
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 16.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 15.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 123.h),
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: GestureDetector(
                      onTap: _isButtonEnabled
                          ? () {
                              // Store name in AuthController for later use
                              final name = _nameController.text.trim();
                              Get.find<AuthController>().setPendingName(name);
                              Get.to(() => const BirthdayScreen());
                            }
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 55.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),
                          gradient: LinearGradient(
                            colors: _isButtonEnabled
                                ? [
                                    const Color(0xFF7247EF),
                                    const Color(0xFFB862E1),
                                  ]
                                : [
                                    const Color(0xFF7247EF).withOpacity(0.4),
                                    const Color(0xFFB862E1).withOpacity(0.4),
                                  ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'continue'.tr,
                          style: TextStyle(
                            color: Colors.white,

                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
