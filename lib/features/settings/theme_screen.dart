import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/assets_manager.dart';

import '../../core/themes/theme_service.dart';
import '../../core/themes/app_dark_colors.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final ThemeService _themeService = ThemeService();

  // 0 = Light, 1 = Dark, 2 = System (Light is active by default)
  late int _selectedThemeIndex = _themeService.isDarkModeActive() ? 1 : 0;

  void _handleThemeSelection(int index) {
    if (index == 0 || index == 1) {
      // Real: applied immediately at the app root (GetMaterialApp reads
      // ThemeService().getThemeMode()) and persisted via GetStorage, not
      // just local widget state that resets on the next screen open.
      final bool isDark = index == 1;
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
      _themeService.saveThemeData(isDark);
      setState(() {
        _selectedThemeIndex = index;
      });
    } else {
      // "System" isn't wired up yet — Light and Dark are the two real,
      // fully-applied options for now.
      _showLiteModeDialog();
    }
  }

  void _showLiteModeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B13E2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF7B13E2),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "System theme isn't available yet — pick Light or Dark",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B13E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: context.shellTextPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Display",
                        style: TextStyle(
                          color: context.shellTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  /// Theme preview cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => _handleThemeSelection(0),
                        child: SvgPicture.asset(AssetsManager.light, width: 40),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(1),
                        child: SvgPicture.asset(AssetsManager.dark, width: 40),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(2),
                        child: SvgPicture.asset(
                          AssetsManager.system,
                          width: 40,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => _handleThemeSelection(0),
                        child: const Text(
                          "Light",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(1),
                        child: const Text(
                          "Dark",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(2),
                        child: const Text(
                          "System",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Selectors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () => _handleThemeSelection(0),
                        child: ThemeSelector(active: _selectedThemeIndex == 0),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(1),
                        child: ThemeSelector(active: _selectedThemeIndex == 1),
                      ),
                      GestureDetector(
                        onTap: () => _handleThemeSelection(2),
                        child: ThemeSelector(active: _selectedThemeIndex == 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  final bool active;

  const ThemeSelector({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.themedColor(
          const Color.fromARGB(255, 241, 241, 241),
          AppDarkColors.card,
        ),
      ),
      child: active
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF7B13E2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
