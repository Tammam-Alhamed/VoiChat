import 'package:flutter/material.dart';

import 'colors.dart';

class GradientHelper {
  static LinearGradient get mainColorsGradient => const LinearGradient(
    colors: [
      MainColors.mainColor,
      MainColors.accentColor,
    ], // Customize your gradient colors
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient get darkModeGradient => const LinearGradient(
    colors: [
      Color.fromARGB(255, 40, 10, 75),
      Color.fromARGB(255, 24, 13, 41),
    ], // Customize your gradient colors
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient get greenColorsGradient => const LinearGradient(
    colors: [Color(0xff07b59a), Color(0xff69da7e)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static LinearGradient get mainColorsGradientReversed2 => const LinearGradient(
    colors: [
      MainColors.accentColor,
      MainColors.mainColor,
    ], // Customize your gradient colors
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get mainColorsGradientReversed => const LinearGradient(
    colors: [Color(0xff1aa9d4), Color(0xff06276c)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static LinearGradient getGradient(String gradName) {
    switch (gradName) {
      case 'red':
        return const LinearGradient(
          colors: [Color(0xffff9567), Color(0xfffe6965)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'green':
        return const LinearGradient(
          colors: [Color(0xff69da7e), Color(0xff07b59a)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'grey':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 49, 49, 49),
            Color.fromARGB(255, 12, 12, 12),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'darkblue':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 12, 12),
            Color.fromARGB(255, 49, 49, 49),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'yellow':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 192, 57),
            Color.fromARGB(255, 255, 227, 143),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'blue':
        return const LinearGradient(
          colors: [Color(0xff1aa9d4), Color.fromARGB(255, 26, 91, 212)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xffa96aed), Color(0xff635df1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'pink':
        return const LinearGradient(
          colors: [Color(0xfff758a2), Color(0xfffc5765)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
    }
    return const LinearGradient(
      colors: [Color(0xffff9567), Color(0xfffe6965)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
  }

  static LinearGradient getBadgeGradient(String gradName) {
    switch (gradName) {
      case 'red':
        return const LinearGradient(
          colors: [Color(0xfffe6965), Color(0xffff9567)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'green':
        return const LinearGradient(
          colors: [Color(0xff07b59a), Color(0xff69da7e)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'grey':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 49, 49, 49),
            Color.fromARGB(255, 12, 12, 12),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'darkblue':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 12, 12),
            Color.fromARGB(255, 49, 49, 49),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'yellow':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 192, 57),
            Color.fromARGB(255, 255, 227, 143),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'blue':
        return const LinearGradient(
          colors: [Color.fromARGB(255, 26, 91, 212), Color(0xff1aa9d4)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xff635df1), Color(0xffa96aed)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'pink':
        return const LinearGradient(
          colors: [Color(0xfffc5765), Color(0xfff758a2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
    }
    return const LinearGradient(
      colors: [Color(0xfffe6965), Color(0xffff9567)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
  }

  static LinearGradient primaryGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [MainColors.gradientStart, MainColors.gradientEnd],
    );
  }

  static LinearGradient shimmerGradient({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        MainColors.shimmerBase,
        MainColors.shimmerHighlight,
        MainColors.shimmerBase,
      ],
    );
  }

  static LinearGradient vipGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [MainColors.vip, Color(0xFFFFE55C)],
    );
  }

  static LinearGradient buttonGradient({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [MainColors.primary, MainColors.secondary],
    );
  }
}
