import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/helpers/avatar_helper.dart';
import '../state/calls_provider.dart';

/// In-call screen — shown once both parties are connected.
///
/// Video mode: shows remote video full-screen + local camera PiP.
/// Audio mode: shows blurred avatar background (like audio call).
///
/// Controls:
///  • Mute / Unmute mic
///  • Toggle camera on/off
///  • Switch front/rear camera
///  • Toggle video ↔ audio mode (affects both parties via LiveKit)
///  • Speaker on/off
///  • End call
class InCallScreen extends StatelessWidget {
  final String callId;
  final String otherPartyName;
  final String? otherPartyImage;
  final String callType;

  const InCallScreen({
    super.key,
    required this.callId,
    required this.otherPartyName,
    this.otherPartyImage,
    this.callType = 'video',
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<CallsProvider>();
    final isVideo = provider.isVideo;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background / Remote video ──────────────────────────────────
            isVideo
                ? _RemoteVideoView(provider: provider, size: size)
                : _buildBlurredBackground(size),

            // Dark overlay for audio mode or when no remote video
            if (!isVideo || provider.remoteVideoTrack == null)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),

            // ── Local PiP camera (video mode) ─────────────────────────────
            if (isVideo && !provider.isCameraOff)
              _LocalVideoPiP(provider: provider, size: size),

            // ── Content overlay ───────────────────────────────────────────
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar: name + call status
                  _buildTopBar(provider),

                  // Bottom controls
                  _buildControls(context, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(CallsProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Show avatar + name only in audio mode
          if (!provider.isVideo || provider.remoteVideoTrack == null) ...[
            const SizedBox(height: 24),
            _buildAvatar(),
            const SizedBox(height: 16),
          ],
          Text(
            otherPartyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.isVideo)
                const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              if (!provider.isVideo)
                const Icon(Icons.call_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                provider.state == CallState.connected
                    ? provider.elapsedFormatted
                    : 'Connecting...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Controls ────────────────────────────────────────────────────────────────

  Widget _buildControls(BuildContext context, CallsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 2: End call (centred) ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_EndCallButton(onTap: () => provider.endCall())],
          ),
          const SizedBox(height: 20),
          // ── Row 1: secondary controls ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute
              _ControlButton(
                icon: provider.isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: provider.isMuted ? 'Unmute' : 'Mute',
                isActive: provider.isMuted,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.18),
                onTap: () => provider.toggleMute(),
              ),

              // Speaker
              _ControlButton(
                icon: provider.isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: provider.isSpeakerOn ? 'Speaker' : 'Earpiece',
                isActive: provider.isSpeakerOn,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.18),
                onTap: () => provider.toggleSpeaker(),
              ),

              // Toggle video/audio mode
              _ControlButton(
                icon: provider.isVideo
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: provider.isVideo ? 'Video' : 'Audio only',
                isActive: provider.isVideo,
                activeColor: const Color(0xFF8B3EE8),
                inactiveColor: Colors.white.withOpacity(0.18),
                onTap: () => provider.toggleVideoMode(),
              ),

              // Switch camera (only in video mode when camera is on)
              _ControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                isActive: false,
                activeColor: Colors.white,
                inactiveColor: provider.isVideo && !provider.isCameraOff
                    ? Colors.white.withOpacity(0.18)
                    : Colors.white.withOpacity(0.06),
                onTap: provider.isVideo && !provider.isCameraOff
                    ? () => provider.switchCamera()
                    : null,
              ),
              _ControlButton(
                icon: Icons.wallet_giftcard_outlined,
                label: 'Gift',
                isActive: false,
                activeColor: Colors.white.withOpacity(0.0),
                inactiveColor: provider.isVideo && !provider.isCameraOff
                    ? Colors.white.withOpacity(0.0)
                    : Colors.white.withOpacity(0.0),
                onTap: provider.isVideo && !provider.isCameraOff
                    ? () => ToastHelper.showInfoToast(
                        message: "Gifts In Call Not Implemented yet",
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Avatar (audio mode) ─────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B3EE8), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B3EE8).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarImage()),
    );
  }

  Widget _buildAvatarImage() {
    final resolvedUrl =
        otherPartyImage != null && otherPartyImage!.isNotEmpty
        ? (otherPartyImage!.startsWith('http')
              ? otherPartyImage!
              : '${Constants.imageUrl}$otherPartyImage')
        : otherPartyImage;
    return AvatarHelper.widget(resolvedUrl, fit: BoxFit.cover);
  }

  Widget _buildBlurredBackground(Size size) {
    if (otherPartyImage != null && otherPartyImage!.isNotEmpty) {
      final imageUrl = otherPartyImage!.startsWith('http')
          ? otherPartyImage!
          : '${Constants.imageUrl}$otherPartyImage';
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2C1B4D)),
      );
    }
    return Container(color: const Color(0xFF2C1B4D));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remote video full-screen view
// ─────────────────────────────────────────────────────────────────────────────
class _RemoteVideoView extends StatelessWidget {
  final CallsProvider provider;
  final Size size;

  const _RemoteVideoView({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    final track = provider.remoteVideoTrack;
    if (track == null) {
      // No remote video yet — show avatar placeholder
      return Container(
        color: const Color(0xFF1A0533),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 60),
              SizedBox(height: 12),
              Text(
                'Waiting for video...',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return VideoTrackRenderer(track);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local camera picture-in-picture (top-right corner)
// ─────────────────────────────────────────────────────────────────────────────
class _LocalVideoPiP extends StatelessWidget {
  final CallsProvider provider;
  final Size size;

  const _LocalVideoPiP({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    final localTrack = provider.localVideoTrack;
    if (localTrack == null) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        clipBehavior: Clip.hardEdge,
        child: VideoTrackRenderer(localTrack),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic control button (secondary row)
// ─────────────────────────────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // color: isActive ? activeColor : inactiveColor,
              ),
              child: Icon(
                icon,
                color: isActive
                    ? const Color.fromARGB(255, 120, 36, 255)
                    : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            /*  Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),*/
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// End call button
// ─────────────────────────────────────────────────────────────────────────────
class _EndCallButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  State<_EndCallButton> createState() => _EndCallButtonState();
}

class _EndCallButtonState extends State<_EndCallButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) {
            _ctrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _ctrl.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE53935),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x99E53935),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'End Call',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
