import 'package:flutter/material.dart';

/// App-wide scrolling without any bounce or overscroll effect.
///
/// Material 3 on Android 12+ shows a "stretch" overscroll effect by default,
/// and iOS uses bouncing physics. The client wants neither: lists simply stop
/// at their edges. Applied once on GetMaterialApp (see main.dart), so every
/// ListView / GridView / PageView / CustomScrollView inherits it.
///
/// Pull-to-refresh (RefreshIndicator) keeps working — it relies on overscroll
/// notifications, which clamping physics still sends.
class NoBounceScrollBehavior extends MaterialScrollBehavior {
  const NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child; // no stretch, no glow
}
