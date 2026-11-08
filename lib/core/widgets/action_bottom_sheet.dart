import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../themes/app_dark_colors.dart';

/// One row inside a unified [showActionBottomSheet] — same visual language
/// (icon, 15px medium text, optional accent color) used by every
/// "pick an action" sheet in the app (profile photo picker, add-post
/// picker, etc.) so they all look and feel identical.
class ActionSheetOption {
  /// Used unless [iconAsset] is provided.
  final IconData? icon;

  /// Optional custom SVG icon (e.g. AssetsManager.addPhoto) — takes
  /// precedence over [icon] when set, so rows that need to match a
  /// specific design asset (rather than the closest Material icon) can.
  final String? iconAsset;

  final String text;

  /// Called after the sheet has already closed itself. Null (or
  /// [enabled] = false) renders the row disabled/greyed-out and un-tappable.
  final VoidCallback? onTap;

  /// Accent color for the icon + text when enabled (e.g. red for a
  /// destructive action). Defaults to near-black.
  final Color? color;

  final bool enabled;

  const ActionSheetOption({
    this.icon,
    this.iconAsset,
    required this.text,
    required this.onTap,
    this.color,
    this.enabled = true,
  }) : assert(
         icon != null || iconAsset != null,
         'Provide either icon or iconAsset',
       );
}

/// Shows the app's single, unified bottom-sheet action list: white sheet,
/// 24px top radius, drag handle, one row per option. This is the one
/// design every "choose an action" sheet in the app should use (profile
/// photo picker, add-post picker, and any future ones) so they're visually
/// consistent instead of each screen inventing its own layout.
Future<void> showActionBottomSheet(
  BuildContext context, {
  required List<ActionSheetOption> options,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: sheetContext.shellSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: sheetContext.themedColor(
                  Colors.grey[300]!,
                  AppDarkColors.border,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            for (final option in options)
              _ActionSheetTile(option: option),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
  );
}

class _ActionSheetTile extends StatelessWidget {
  final ActionSheetOption option;

  const _ActionSheetTile({required this.option});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = !option.enabled
        ? Colors.grey
        : (option.color ??
              context.themedColor(
                const Color.fromARGB(255, 30, 30, 30),
                AppDarkColors.textPrimary,
              ));

    return ListTile(
      enabled: option.enabled,
      onTap: option.enabled
          ? () {
              Navigator.pop(context);
              option.onTap?.call();
            }
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: option.iconAsset != null
            ? SvgPicture.asset(
                option.iconAsset!,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
              )
            : Icon(option.icon, color: effectiveColor),
      ),
      title: Text(
        option.text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: effectiveColor,
        ),
      ),
    );
  }
}
