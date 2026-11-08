import 'package:flutter/material.dart';

import '../themes/app_dark_colors.dart';

/// Unified search field used across the whole app (Messages, Following,
/// Search by ID, Country picker, ...). Visual spec is taken 1:1 from the
/// original Messages tab search bar so every screen looks identical:
/// - height 45, radius 12
/// - light-gray background (never plain white, never a "dark" flat color)
/// - same icon, same hint color, same padding
///
/// Only the container/hint/icon colors are theme-aware (via
/// [BuildContext.themedColor]); in light mode every value below resolves to
/// the exact literal the Messages tab already used, so light mode is
/// pixel-identical to before this widget existed.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'search',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.themedColor(
          const Color(0xFFF5F5F5),
          AppDarkColors.card,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset(
            "assets/icons/search.png",
            width: 20,
            height: 20,
            color: context.isAppDarkMode ? AppDarkColors.textSecondary : null,
            colorBlendMode: context.isAppDarkMode ? BlendMode.srcIn : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              autofocus: autofocus,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              textInputAction: textInputAction,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: context.themedColor(
                    const Color(0xFFB0B0B0),
                    AppDarkColors.textSecondary,
                  ),
                  fontSize: 15,
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
