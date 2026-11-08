import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/helpers/avatar_helper.dart';
import '../state/calls_provider.dart';

/// Outgoing call screen — shown when the current user initiates a call.
///
/// Displays "Connecting..." animation while waiting for the receiver.
/// Supports video and voice call modes.
class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String name;
  final String? avatarUrl;
  final int coinsPerMinute;
  final String callType; // 'video' | 'audio'

  const OutgoingCallScreen({
    super.key,
    required this.callId,
    this.name = 'Unknown',
    this.avatarUrl,
    this.coinsPerMinute = 80,
    this.callType = 'video',
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _dotsCtrl;

  bool _isEnding = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);

    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(
      begin: 0.55,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  void _onEndCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    final provider = context.read<CallsProvider>();
    await provider.endCall();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──────────────────────────────────────────────
            _buildBackground(size),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Call type badge
                  _buildCallTypeBadge(),

                  const SizedBox(height: 20),

                  // Avatar with pulsing ring
                  _PulsingAvatar(
                    pulseScale: _pulseScale,
                    pulseOpacity: _pulseOpacity,
                    avatarUrl: widget.avatarUrl,
                  ),

                  const SizedBox(height: 20),

                  // Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // "Connecting..." animated dots
                  _ConnectingText(controller: _dotsCtrl),

                  const Spacer(flex: 3),

                  // Coins per minute
                  Text(
                    '${widget.coinsPerMinute} coins/min',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  // End call button
                  if (_isEnding)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Column(
                      children: [
                        _EndCallButton(onTap: _onEndCall),
                        const SizedBox(height: 8),
                        const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTypeBadge() {
    final isVideo = widget.callType == 'video';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isVideo ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      final imageUrl = widget.avatarUrl!.startsWith('http')
          ? widget.avatarUrl!
          : '${Constants.imageUrl}${widget.avatarUrl}';
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF3D2060)),
      );
    }
    return Container(color: const Color(0xFF3D2060));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing avatar
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingAvatar extends StatelessWidget {
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final String? avatarUrl;

  const _PulsingAvatar({
    required this.pulseScale,
    required this.pulseOpacity,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseScale,
            builder: (_, __) => Opacity(
              opacity: pulseOpacity.value,
              child: Transform.scale(
                scale: pulseScale.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF9B59B6),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 106,
            height: 106,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF7B2FBE),
                  Color(0xFFAA5FE0),
                  Color(0xFF7B2FBE),
                ],
              ),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          ClipOval(
            child: SizedBox(width: 92, height: 92, child: _buildAvatarImage()),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    return AvatarHelper.widget(avatarUrl, fit: BoxFit.cover);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Connecting..." animated dots
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectingText extends StatelessWidget {
  final AnimationController controller;
  const _ConnectingText({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final dotCount = (controller.value * 4).floor() % 4;
        final dots = '.' * dotCount;
        return Text(
          'Connecting$dots',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Red end-call button with press animation
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
