import 'package:flutter/material.dart';
import 'package:shoeebapk/core/themes/app_dark_colors.dart';

import 'package:get/get.dart';
import '../session/presentation/controllers/session_controller.dart';

class LinkedDeviceScreen extends StatelessWidget {
  const LinkedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: AppBar(
        backgroundColor: context.shellBackground,
        elevation: 0,
        foregroundColor: context.shellTextPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Linked Device",
          style: TextStyle(
            color: context.shellTextPrimary,
            fontSize: 22,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Text(
              "Current Device",
              style: TextStyle(
                color: Color(0xFF7A7A7A),
                fontSize: 12,
                fontFamily: 'SF Pro',
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            ...Get.find<SessionController>().session!.userDevices.map(
              (device) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.smartphone, size: 26),
                title: Text(
                  '${device.deviceName} - ${device.deviceType}' ?? "unknown",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '${device.lastUsedAt.toString().substring(0, 10)} - ${device.ipAddress}' ??
                        device.deviceId ??
                        "unknown",
                    style: TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 12,
                      fontFamily: 'SF Pro',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
