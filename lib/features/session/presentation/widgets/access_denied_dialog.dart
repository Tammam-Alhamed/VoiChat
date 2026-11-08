import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Non-dismissible dialog shown when the account or device is banned. The
/// only action closes the app.
class AccessDeniedDialog extends StatelessWidget {
  final String message;

  const AccessDeniedDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.block, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            'access_denied'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => exit(0),
          child: Text(
            'exit_app'.tr,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
