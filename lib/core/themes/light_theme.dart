import 'package:flutter/material.dart';

import 'colors.dart';
import '../helpers/hex_helpers.dart';

class LightThemeService {
  static final lightTheme = ThemeData.light().copyWith(
    primaryColor: MainColors.mainColor,
    appBarTheme: const AppBarTheme().copyWith(
      color: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: buildMaterialColor(MainColors.mainColor),
      backgroundColor: const Color(0xFFeeeeee),
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F2),
    dividerColor: Colors.black12,
    brightness: Brightness.light,
    cardColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    focusColor: const Color(0xFFADC4C8),
    hintColor: const Color(0xFF52575C),

    // Add switchTheme to customize switch appearance
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade400;
        }
        if (states.contains(WidgetState.selected)) {
          return MainColors.mainColor;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade200;
        }
        if (states.contains(WidgetState.selected)) {
          return MainColors.mainColor.withValues(alpha: 0.5);
        }
        return Colors.grey.shade300; // More visible inactive track color
      }),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(color: Colors.black),
      ),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Tajawal',
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    primaryTextTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Tajawal',
      bodyColor: Colors.black54,
      displayColor: Colors.black54,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
