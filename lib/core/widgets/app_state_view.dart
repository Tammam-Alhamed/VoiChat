import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// One consistent look for every "nothing to show" or "something went
/// wrong" screen in the app: a soft circular icon badge, a title, an
/// optional message, and a single gradient pill button (Retry / Go Back /
/// whatever fits). Used via the [AppStateView.error] and [AppStateView.empty]
/// factories so every screen gets the same icon + same button by default,
/// instead of every screen inventing its own.
class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// A failed request — same icon and "Retry" button everywhere.
  factory AppStateView.error({
    Key? key,
    String? title,
    String? message,
    required VoidCallback onRetry,
  }) {
    return AppStateView(
      key: key,
      icon: Icons.wifi_off_rounded,
      title: title ?? 'something_went_wrong'.tr,
      message: message ?? 'check_connection_retry'.tr,
      actionLabel: 'retry'.tr,
      onAction: onRetry,
    );
  }

  /// Nothing to show. The action is optional — omit it for a plain empty
  /// list, pass onGoBack for a dead-end screen (banned/blocked/not found).
  factory AppStateView.empty({
    Key? key,
    IconData icon = Icons.inbox_rounded,
    String? title,
    String? message,
    String? actionLabel,
    VoidCallback? onGoBack,
  }) {
    return AppStateView(
      key: key,
      icon: icon,
      title: title ?? 'nothing_here_yet'.tr,
      message: message,
      actionLabel: onGoBack != null ? (actionLabel ?? 'go_back'.tr) : null,
      onAction: onGoBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.black).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor ?? Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: onAction,
                      child: Center(
                        child: Text(
                          actionLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
