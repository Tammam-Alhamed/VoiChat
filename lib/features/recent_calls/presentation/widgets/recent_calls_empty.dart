import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_state_view.dart';

class RecentCallsEmpty extends StatelessWidget {
  const RecentCallsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateView.illustratedEmpty(
      icon: Icons.phone_outlined,
      iconAsset: 'assets/icons/calls.svg',
      title: 'no_recent_calls'.tr,
      message: 'pull_down_to_refresh'.tr,
    );
  }
}
