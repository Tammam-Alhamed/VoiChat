import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'core/helpers/navigation_service.dart';
import 'core/helpers/deep_link_service.dart';
import 'core/helpers/notification_helper.dart';
import 'core/localization/localization_service.dart';
import 'core/providers/provider_list.dart';
import 'core/themes/app_dark_colors.dart';
import 'core/themes/colors.dart';
import 'core/themes/dark_theme.dart';
import 'core/themes/light_theme.dart';
import 'core/themes/theme_service.dart';
import 'core/utils/http_overrides.dart';
import 'core/utils/no_bounce_scroll_behavior.dart';
import 'features/session/presentation/screens/splash_screen.dart';
import 'app/di/injection_container.dart' as di;
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ── FCM background handler must be top-level ──────────────────────────────────
// Registered here and passed to FirebaseMessaging.onBackgroundMessage.
// The actual implementation lives in NotificationHelper for co-location.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    firebaseMessagingBackgroundHandler(message);

// ─────────────────────────────────────────────────────────────────────────────

Future<void> initializeFirebase() async {
  if (Platform.isWindows) return;

  try {
    await Firebase.initializeApp();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      await NotificationHelper.initialize();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}

Future<void> initialize() async {
  await di.init();
  await GetStorage.init();
  await initializeFirebase();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await initialize();

  // Shared profile links (https://api.voichat.live/u/<id>)
  DeepLinkService.instance.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: MainColors.mainColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(
    MultiProvider(
      providers: ProviderManager.getProviderList(),
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return GetMaterialApp(
            showPerformanceOverlay: false, // 🌟 هذا السطر يفعل شريط الأداء
            debugShowCheckedModeBanner: false,
            // No bounce / stretch overscroll anywhere in the app.
            scrollBehavior: const NoBounceScrollBehavior(),
            key: GlobalKey(),
            locale: LocalizationService.initLanguage(),
            fallbackLocale: LocalizationService.fallbackLocale,
            translations: LocalizationService(),
            navigatorKey: NavigationService.navigatorKey,
            theme: LightThemeService.lightTheme,
            darkTheme: DarkThemeService.darkTheme,
            themeMode: ThemeService().getThemeMode(),
            // One consistent transition for every screen in the app: push
            // slides in from the right, back slides out to the right — the
            // same native feel everywhere, from the first screen to the last.
            defaultTransition: Transition.cupertino,
            transitionDuration: const Duration(milliseconds: 300),
            // Every `Skeletonizer(...)` shimmer loader in the app (chat
            // lists, story rows, profile, recent calls, ...) shares this one
            // config instead of each screen inventing its own shimmer
            // colors. In light mode we don't touch the tree at all — `child`
            // passes straight through — so light mode's shimmer look is
            // exactly what it always was. Dark mode gets a shimmer that
            // actually reads as "loading" against the dark background
            // instead of a stray light-gray box.
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              if (!isDark) return child;
              return SkeletonizerConfig(
                data: SkeletonizerConfigData(
                  effect: const ShimmerEffect(
                    baseColor: AppDarkColors.card,
                    highlightColor: AppDarkColors.surface,
                  ),
                  containersColor: AppDarkColors.card,
                ),
                child: child,
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    ),
  );
}
