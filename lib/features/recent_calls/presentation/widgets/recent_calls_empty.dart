import 'package:flutter/material.dart';

class RecentCallsEmpty extends StatelessWidget {
  const RecentCallsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_missed_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No recent calls found",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
