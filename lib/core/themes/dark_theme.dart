import 'package:flutter/material.dart';

import 'colors.dart';
import 'app_dark_colors.dart';

class DarkThemeService {
  static final darkTheme = ThemeData.dark().copyWith(
    primaryColor: MainColors.mainColor,
    appBarTheme: const AppBarTheme().copyWith(
        color: AppDarkColors.surface,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white)),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      backgroundColor: AppDarkColors.background,
    ).copyWith(
      surface: AppDarkColors.surface,
      secondary: AppDarkColors.accent,
    ),
    dividerColor: AppDarkColors.divider,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppDarkColors.background,
    cardColor: AppDarkColors.card,
    hintColor: const Color(0xFFE7F6F8),
    focusColor: const Color(0xFFADC4C8),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      // primary: Colors.white,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(color: Colors.white),
    )),
    textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Tajawal',
        bodyColor: const Color.fromARGB(255, 196, 196, 196),
        displayColor: const Color.fromARGB(255, 196, 196, 196)),
    primaryTextTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Tajawal',
        bodyColor: const Color.fromARGB(255, 196, 196, 196),
        displayColor: const Color.fromARGB(255, 196, 196, 196)),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    }),
  );
}
