import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/widgets/app_state_view.dart';
import '../../../core/themes/app_dark_colors.dart';

/// 1. حالة التحميل باستخدام Skeletonizer
class ProfileLoadingWidget extends StatelessWidget {
  final Widget child;
  const ProfileLoadingWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // نغلف المحتوى بـ Skeletonizer دون تغيير الـ Layout
    return Skeletonizer(enabled: true, child: child);
  }
}

/// 2. حالة الحساب المحظور (Banned)
class ProfileBannedWidget extends StatelessWidget {
  final String reason;
  final VoidCallback onBack;

  const ProfileBannedWidget({
    super.key,
    required this.reason,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: AppStateView(
        icon: Icons.gavel_rounded,
        title: "Account Suspended",
        message: reason,
        actionLabel: "Go Back",
        onAction: onBack,
      ),
    );
  }
}

/// 3. حالة الحساب المبلك (Blocked)
class ProfileBlockedWidget extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileBlockedWidget({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: AppStateView(
        icon: Icons.block,
        title: "Profile Unavailable",
        message: "You have blocked this user or you are blocked.",
        actionLabel: "Go Back",
        onAction: onBack,
      ),
    );
  }
}

/// 4. حالة الحساب غير الموجود (Empty)
class ProfileEmptyWidget extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileEmptyWidget({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: AppStateView(
        icon: Icons.person_search,
        title: "User Not Found",
        actionLabel: "Go Back",
        onAction: onBack,
      ),
    );
  }
}

/// 5. حالة حدوث خطأ في الشبكة (Error)
class ProfileErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const ProfileErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: AppStateView.error(message: error, onRetry: onRetry),
    );
  }
}
