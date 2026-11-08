import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class LogOutBottomSheet extends StatefulWidget {
  const LogOutBottomSheet({super.key});

  @override
  State<LogOutBottomSheet> createState() => _LogOutBottomSheetState();
}

class _LogOutBottomSheetState extends State<LogOutBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    // Clears the whole session and opens the login screen.
    await Get.find<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Title
          const Text(
            "Log Out",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 25),

          /// Message
          const Text(
            "Are you sure you want to log out of VoiChat?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 35),

          /// Logout Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _isLoading ? null : _handleLogout,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// Cancel Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              side: const BorderSide(color: Color(0xFFBBBBBB)),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
