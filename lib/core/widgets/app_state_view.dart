import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../themes/app_dark_colors.dart';

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
  final bool illustratedEmpty;
  final String? iconAsset;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.illustratedEmpty = false,
    this.iconAsset,
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

  /// The centered icon/title/description layout used by content-only empty
  /// areas. Existing error and empty states keep their original appearance.
  factory AppStateView.illustratedEmpty({
    Key? key,
    required IconData icon,
    required String title,
    required String message,
    String? iconAsset,
  }) {
    return AppStateView(
      key: key,
      icon: icon,
      title: title,
      message: message,
      iconColor: const Color(0xFF8629F3),
      illustratedEmpty: true,
      iconAsset: iconAsset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(illustratedEmpty ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustratedEmpty)
              iconAsset == null
                  ? Icon(icon, size: 64, color: iconColor)
                  : SvgPicture.asset(
                      iconAsset!,
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(iconColor!, BlendMode.srcIn),
                    )
            else
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.black).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor ?? Colors.black),
              ),
            SizedBox(height: illustratedEmpty ? 24 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: illustratedEmpty ? 22 : 17,
                fontWeight: illustratedEmpty ? FontWeight.w400 : FontWeight.bold,
                color: illustratedEmpty
                    ? context.shellTextPrimary
                    : Colors.black87,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: illustratedEmpty ? 12 : 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: illustratedEmpty ? 16 : 13,
                  color: illustratedEmpty
                      ? context.shellTextSecondary
                      : Colors.grey.shade600,
                ),
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
