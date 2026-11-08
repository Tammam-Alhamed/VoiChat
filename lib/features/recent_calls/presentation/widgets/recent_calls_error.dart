import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_view.dart';

class RecentCallsError extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const RecentCallsError({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateView.error(message: errorMessage, onRetry: onRetry);
  }
}
