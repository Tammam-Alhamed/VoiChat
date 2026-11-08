import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoeebapk/core/assets_manager.dart';

import '../core/constants.dart';
import '../core/helpers/toast_helper.dart';
import 'live_filters.dart';
import 'live_goal_widgets.dart';

import '../features/session/presentation/controllers/session_controller.dart';
import '../features/live/presentation/controllers/live_entry_controller.dart';

/// Pre-live preview & setup. "Go Live" on the home screen opens this instead
/// of starting the broadcast right away: the host sees their camera, can
/// set a gift goal, pick a filter and share, and only the Go Live button
/// here actually starts the stream.
class GoLiveSetupScreen extends StatefulWidget {
  const GoLiveSetupScreen({super.key});

  @override
  State<GoLiveSetupScreen> createState() => _GoLiveSetupScreenState();
}

class _GoLiveSetupScreenState extends State<GoLiveSetupScreen> {
  static const _purple = Color(0xFF6A3BF5);

  LocalVideoTrack? _cameraTrack;
  bool _cameraFailed = false;

  int? _goalAmount;
  String _filterId = LiveFilters.none;
  bool _isFilterPanelOpen = false;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  @override
  void dispose() {
    _releaseCamera();
    super.dispose();
  }

  // ─── Camera preview ─────────────────────────────────────────────────────────

  Future<void> _startPreview() async {
    try {
      final track = await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(cameraPosition: CameraPosition.front),
      );
      if (!mounted) {
        await track.stop();
        await track.dispose();
        return;
      }
      setState(() {
        _cameraTrack = track;
        _cameraFailed = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  /// The live room opens its own camera track, so the preview has to let
  /// go of the camera first.
  Future<void> _releaseCamera() async {
    final track = _cameraTrack;
    _cameraTrack = null;
    await _stopTrack(track);
  }

  static Future<void> _stopTrack(LocalVideoTrack? track) async {
    if (track == null) return;
    try {
      await track.stop();
      await track.dispose();
    } catch (_) {
      // best-effort
    }
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  Future<void> _goLive() async {
    if (_isStarting) return;
    HapticFeedback.mediumImpact();

    // Drop the preview from the tree first, then free the camera.
    final previewTrack = _cameraTrack;
    setState(() {
      _isStarting = true;
      _isFilterPanelOpen = false;
      _cameraTrack = null;
    });
    await _stopTrack(previewTrack);
    if (!mounted) return;

    final started = await Get.find<LiveEntryController>().startLiveStream(
      goalAmount: _goalAmount,
      filterId: _filterId,
    );

    // On success this screen has already been replaced by the live room.
    if (!started && mounted) {
      setState(() => _isStarting = false);
      _startPreview();
    }
  }

  /// Shares a link to the host's profile. Tapping it (WhatsApp, etc.) opens
  /// the app on this profile; without the app it opens a web page with a
  /// download button.
  Future<void> _share() async {
    final id = Get.find<SessionController>().session?.user?.profileId;
    if (id == null || id.isEmpty) {
      ToastHelper.showErrorToast(message: "Couldn't create your profile link");
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text:
            "I'm going live on Voichat now! Come and watch 🎥\n"
            "${Constants.profileLink(id)}",
      ),
    );
  }

  Future<void> _openGoal() async {
    setState(() => _isFilterPanelOpen = false);
    if (_goalAmount == null) {
      final amount = await showSetGoalDialog(context);
      if (amount != null && mounted) setState(() => _goalAmount = amount);
    } else {
      final cancel = await showCurrentGoalDialog(
        context,
        targetAmount: _goalAmount!,
      );
      if (cancel == true && mounted) setState(() => _goalAmount = null);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            SafeArea(
              child: Stack(
                children: [
                  // Back
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: _isStarting ? null : () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  // Right-side actions: share, goal, filters
                  Positioned(
                    top: 12,
                    right: 14,
                    child: Column(
                      children: [
                        _sideButton(
                          tooltip: 'Share',
                          onTap: _share,
                          child: SvgPicture.asset(
                            AssetsManager.share,
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sideButton(
                          tooltip: 'Goal',
                          active: _goalAmount != null,
                          onTap: _openGoal,
                          child: const GoalIcon(color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 14),
                        _sideButton(
                          tooltip: 'Filters',
                          active: _filterId != LiveFilters.none,
                          onTap: () => setState(
                            () => _isFilterPanelOpen = !_isFilterPanelOpen,
                          ),
                          child: SvgPicture.asset(
                            AssetsManager.liveFilter,
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom: filter picker (when open) + Go Live
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isFilterPanelOpen
                              ? _buildFilterRow()
                              : const SizedBox.shrink(),
                        ),
                        _buildGoLiveButton(),
                      ],
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

  Widget _buildPreview() {
    final track = _cameraTrack;
    Widget video;
    if (track != null) {
      // IgnorePointer: on Android the camera view can be a native view that
      // swallows touches meant for the buttons/filters drawn over it.
      video = IgnorePointer(
        child: VideoTrackRenderer(
          track,
          fit: VideoViewFit.cover,
          mirrorMode: VideoViewMirrorMode.mirror,
        ),
      );
    } else if (_cameraFailed) {
      video = Container(
        color: const Color(0xFF1E1E24),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera preview unavailable.\nCheck the camera permission and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startPreview,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      video = Container(
        color: const Color(0xFF1E1E24),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white54),
      );
    }

    final tint = LiveFilters.tintFor(_filterId);
    return Stack(
      fit: StackFit.expand,
      children: [
        video,
        // Painted overlay (same approach as the live room).
        if (tint != null) IgnorePointer(child: Container(color: tint)),
      ],
    );
  }

  Widget _sideButton({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: _isStarting ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _purple : Colors.black.withOpacity(0.22),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _purple.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final track = _cameraTrack;
    return Container(
      key: const ValueKey('filters'),
      height: 96,
      margin: const EdgeInsets.only(bottom: 18),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: LiveFilters.labels.entries.map((e) {
          final id = e.key;
          final isActive = _filterId == id;
          final tint = LiveFilters.tintFor(id);
          final size = isActive ? 64.0 : 56.0;
          return GestureDetector(
            // Whole chip is tappable, including over the live preview.
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _filterId = id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(isActive ? 3 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (track != null)
                            // Native video views can eat taps — the chip's
                            // GestureDetector must get them instead.
                            IgnorePointer(
                              child: VideoTrackRenderer(
                                track,
                                fit: VideoViewFit.cover,
                                mirrorMode: VideoViewMirrorMode.mirror,
                              ),
                            )
                          else
                            Container(color: const Color(0xFF3A3A3A)),
                          if (tint != null)
                            IgnorePointer(child: Container(color: tint)),
                          if (id == LiveFilters.none)
                            const Center(
                              child: Icon(
                                Icons.not_interested_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    e.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoLiveButton() {
    return GestureDetector(
      onTap: _goLive,
      child: Container(
        width: 230,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF5530F7), Color(0xFFB25AEE)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A3BF5).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _isStarting
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.6,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 26, color: Colors.white54),
                  const SizedBox(width: 14),
                  const Text(
                    'Go Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
