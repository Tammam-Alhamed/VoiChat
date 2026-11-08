import 'package:flutter/material.dart';

/// Real dark-mode palette, sourced from the Figma file's own dark-theme
/// preview (node 666:2906, the "Dark" thumbnail on the Display/theme
/// settings screen). That thumbnail's background is a
/// `rgba(6,9,18,0.84) -> rgba(17,16,50,0.84)` gradient; flattened over
/// black (how it renders as a phone-screen preview) that resolves to the
/// two solid colors below.
///
/// Light mode is intentionally untouched anywhere in the app — these
/// colors are only ever used behind an `isDarkMode` check.
class AppDarkColors {
  AppDarkColors._();

  /// Darkest stop of the Figma gradient — used for scaffold/page background.
  static const Color background = Color(0xFF05080F);

  /// Lighter stop of the Figma gradient — used for surfaces sitting just
  /// above the background (app bars, bottom nav bar, sheets).
  static const Color surface = Color(0xFF0E0D2A);

  /// One step lighter again — used for cards/tiles that need to stand out
  /// from `surface`.
  static const Color card = Color(0xFF15142E);

  /// Accent purple from the same Figma thumbnail
  /// (`rgba(140,45,234,0.92)` / `#7B13E2`), which is already the app's
  /// existing brand purple used for CTAs and badges — kept identical in
  /// both themes on purpose.
  static const Color accent = Color(0xFF8C2DEA);

  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFFB2B2B2);
  static const Color divider = Colors.white12;
  static const Color border = Color(0xFF2A2942);
}

/// Small ergonomic helper so screens can flip a single hardcoded light
/// value to its dark counterpart with one line, e.g.:
/// `color: context.themedColor(Colors.white, AppDarkColors.background)`
extension AppThemeContext on BuildContext {
  // Named `isAppDarkMode` (not `isDarkMode`) on purpose: GetX's own
  // `ContextExtensionss` (pulled in transitively via package:get) already
  // defines a same-named `isDarkMode` getter on BuildContext, and having
  // two extensions declare the same member makes every `context.isDarkMode`
  // call ambiguous wherever both are in scope.
  bool get isAppDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color themedColor(Color lightColor, Color darkColor) =>
      isAppDarkMode ? darkColor : lightColor;

  Color get shellBackground =>
      themedColor(Colors.white, AppDarkColors.background);

  Color get shellSurface =>
      themedColor(Colors.white, AppDarkColors.surface);

  Color get shellCard => themedColor(Colors.white, AppDarkColors.card);

  Color get shellTextPrimary =>
      themedColor(Colors.black, AppDarkColors.textPrimary);

  Color get shellTextSecondary =>
      themedColor(const Color(0xFF666666), AppDarkColors.textSecondary);

  Color get shellDivider => themedColor(Colors.black12, AppDarkColors.divider);

  /// Shimmer/skeleton placeholder box fill (loading avatars, text-line
  /// bars, image placeholders, ...) — one shared spot instead of every
  /// screen hardcoding its own `Color(0xFFEAEAEA)` / `Colors.grey.shadeXXX`.
  Color get shellSkeleton =>
      themedColor(const Color(0xFFEAEAEA), AppDarkColors.card);

  /// Background of an avatar/CircleAvatar before its network image loads
  /// (or when there is no image at all).
  Color get shellAvatarPlaceholder =>
      themedColor(Colors.grey.shade200, AppDarkColors.card);

  /// Inactive icon tint (bottom nav, unselected tab icons, ...).
  Color get shellIconInactive =>
      themedColor(const Color(0xFF666666), AppDarkColors.textSecondary);
}
