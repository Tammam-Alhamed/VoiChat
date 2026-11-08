import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Asks the host whether to go back to a live that is still running.
/// Pops with true (resume) or false (end it).
class ResumeLiveDialog extends StatelessWidget {
  const ResumeLiveDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Your live is still on',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'You were disconnected from your live stream. Go back to it? Your goal and progress are saved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text(
            'End live',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text(
            'Resume',
            style: TextStyle(
              color: Color(0xFF6A3BF5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
