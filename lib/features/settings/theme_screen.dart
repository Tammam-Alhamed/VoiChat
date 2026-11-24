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
              Text(
                'display_system_unavailable'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  child: Text(
                    'display_ok'.tr,
                    style: const TextStyle(
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: context.shellTextPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'display'.tr,
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
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      index: 0,
                      asset: AssetsManager.light,
                      label: 'display_light'.tr,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      index: 1,
                      asset: AssetsManager.dark,
                      label: 'display_dark'.tr,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      index: 2,
                      asset: AssetsManager.system,
                      label: 'display_system'.tr,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required int index,
    required String asset,
    required String label,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _handleThemeSelection(index),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 75),
            child: AspectRatio(
              aspectRatio: 75 / 120,
              child: SvgPicture.asset(asset, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.shellTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ThemeSelector(active: _selectedThemeIndex == index),
        ],
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
