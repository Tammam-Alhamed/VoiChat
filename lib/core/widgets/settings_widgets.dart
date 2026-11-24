import 'package:flutter/material.dart';

/// Shared building blocks for the settings-style screens (Account, Privacy,
/// Notifications, Account Center...). One source of truth for row spacing,
/// icon-to-text gap and font sizes so every page looks identical.
///
/// The matching top bar lives in `settings_app_bar.dart` (SettingsAppBar).

class SettingsMetrics {
  SettingsMetrics._();

  /// Horizontal padding used by every settings page body.
  static const double pagePadding = 18;

  /// Gap between a leading icon/avatar and the title text in a settings row.
  static const double iconTextGap = 12;

  /// Vertical padding inside a settings row (tappable area height).
  static const double rowVerticalPadding = 10;

  /// Primary label size for setting rows.
  static const double rowTitleSize = 16;

  /// Secondary value/subtitle/description size for setting rows.
  static const double rowSubtitleSize = 13;

  /// Section header ("Personal Info", "Other"...) size.
  static const double sectionHeaderSize = 12;

  /// Screen title size in the custom top bars.
  static const double screenTitleSize = 18;

  /// Standard toggle (Switch) size — identical on every page.
  static const double switchScale = 0.85;

  /// Grey used for section headers, subtitles and secondary text.
  static const Color secondaryText = Color(0xFF7A7A7A);
}

/// The app's settings toggle with one fixed size everywhere
/// (Privacy page vs Notifications page must look identical).
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 64,
        height: 40,
        child: Transform.scale(
          scale: SettingsMetrics.switchScale,
          child: Switch(
            value: value,
            activeTrackColor: const Color(0xFF7B13E2),
            inactiveTrackColor: const Color(0xFFE3E3E3),
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}


/// Small grey caption that groups the rows below it.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: SettingsMetrics.sectionHeaderSize,
          fontWeight: FontWeight.w500,
          color: SettingsMetrics.secondaryText,
        ),
      ),
    );
  }
}

/// A single settings row: optional leading icon, title, optional subtitle,
/// optional trailing widget (chevron / lock / add) and tap handler.
/// Used on Account, Privacy and any other option-list page.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final defaultTitleStyle = TextStyle(
      fontSize: SettingsMetrics.rowTitleSize,
      color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SettingsMetrics.rowVerticalPadding,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 24),
              const SizedBox(width: SettingsMetrics.iconTextGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: titleStyle ?? defaultTitleStyle,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: SettingsMetrics.rowSubtitleSize,
                        color: SettingsMetrics.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SettingsMetrics.iconTextGap),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard right chevron used as the trailing of navigation rows.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right,
      size: 24,
      color: SettingsMetrics.secondaryText,
    );
  }
}
