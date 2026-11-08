import 'package:flutter/material.dart';

import '../../../../core/themes/app_dark_colors.dart';

/// Plain "Recent Calls" title row. Selection mode (long-press a call item)
/// swaps this whole header out for a toolbar with Select All / Delete —
/// see RecentCallsTab._buildSelectionToolbar — so this header no longer
/// carries any action of its own.
class RecentCallsHeader extends StatelessWidget {
  const RecentCallsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Calls",
                style: TextStyle(
                  color: context.shellTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
