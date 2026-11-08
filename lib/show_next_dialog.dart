import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showPaymentGateAlert() {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content tightly
          children: [
            // Modern Animated/Styled Icon Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFFF6B6B),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // Dialog Title
            const Text(
              "تنبيه الأمان والخدمة",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Cairo', // Dynamic alignment for Arabic
              ),
            ),
            const SizedBox(height: 12),

            // Your Message
            const Text(
              "ستعمل هذه الميزة بعد تفعيل بوابة الدفع التلقائي في حسابك.",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 32),

            // Modern Gradient Action Button
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7247EF).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  "حسناً، فهمت",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true, // Allows user to tap outside to dismiss
    transitionCurve: Curves.easeInOutBack, // Smooth upscale animation
  );
}
