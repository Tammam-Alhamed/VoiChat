import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

import '../controllers/session_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Purely cosmetic branding animation — it never gates navigation below.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Defer to after the first frame instead of calling _bootstrap()
    // directly. _bootstrap() is async, but Dart runs its synchronous
    // prefix immediately — so the `!isLoggedIn` fast path (Get.offAll at
    // line ~60, below) was firing synchronously inside initState(), i.e.
    // while THIS widget's own first build/mount was still in progress.
    // That throws "setState() or markNeedsBuild() called during build" on
    // the Navigator's _ModalScope, which leaves the Navigator's internal
    // lock stuck and throws the follow-up '!navigator._debugLocked'
    // assertion on the next push — exactly the crash reported. Waiting for
    // the post-frame callback guarantees the whole widget tree has
    // finished its first build before we touch the Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final session = Get.find<SessionController>();

    if (!session.hasStoredLogin) {
      Get.offAll(() => const AuthScreen());
      return;
    }

    // Fast path: a local snapshot exists (returning user), so open Home
    // right away and revalidate with the server in the background.
    if (session.hydrateFromCache()) {
      Get.offAll(() => const HomeScreen());
      unawaited(session.refreshSessionInBackground());
      return;
    }

    // Slow path: nothing cached on this device yet (first login), so one
    // round trip is needed before there is anything to show. The "Access
    // Denied" dialog is shown by verifySessionOrBlock() when blocked.
    final isAllowed = await session.verifySessionOrBlock();
    if (!mounted || !isAllowed) return;

    Get.offAll(() => const HomeScreen());
    unawaited(session.syncFcmToken());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff060912), Color(0xff111032)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SizedBox(
                    width: 180.w,
                    height: 120.h,
                    child: Image.asset(
                      "assets/images/voichatlogoneno.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // App name
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0xFF190B0B),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      "VoiChat",
                      style: TextStyle(
                        fontFamily: "ZenDots",
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
