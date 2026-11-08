import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/helpers/avatar_helper.dart';
import '../state/calls_provider.dart';

/// Incoming call screen — shown when a push notification or socket event
/// delivers an incoming call.
///
/// Wired to [CallsProvider] for accept/reject actions.
///
/// Handles the "caller cancelled" scenario: if [CallsProvider] state flips to
/// [CallState.idle] while this screen is visible (i.e. the caller hung up
/// before the receiver answered), the screen automatically dismisses itself.
class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String name;
  final String? avatarUrl;
  final int coinsPerMinute;
  final String callType; // 'video' | 'audio'

  const IncomingCallScreen({
    super.key,
    required this.callId,
    this.name = 'Unknown',
    this.avatarUrl,
    this.coinsPerMinute = 80,
    this.callType = 'video',
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  bool _isProcessing = false;
  bool _dismissed = false;

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
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onAccept() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final provider = context.read<CallsProvider>();
    await provider.answerCall();
  }

  void _onReject() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final provider = context.read<CallsProvider>();
    await provider.declineCall();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Watch provider — if state becomes idle (caller cancelled or timeout),
    // auto-dismiss this screen.
    return Consumer<CallsProvider>(
      builder: (context, provider, _) {
        // Auto-dismiss when caller cancels mid-ring
        if (!_dismissed && provider.state == CallState.idle && !_isProcessing) {
          _dismissed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
        }

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background ────────────────────────────────────────────
                _buildBackground(size),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),

                // ── Main content ─────────────────────────────────────────
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

                      // Subtitle
                      Text(
                        widget.callType == 'video'
                            ? 'Incoming video call'
                            : 'Incoming voice call',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Coins per minute
                      Text(
                        '${widget.coinsPerMinute} coins/min',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Action buttons — Reject (red) & Accept (green)
                      if (_isProcessing)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // ── Reject (red) ──────────────────────────
                              _CallActionButton(
                                icon: Icons.call_end_rounded,
                                color: const Color(0xFFE53935),
                                shadowColor: const Color(0x99E53935),
                                label: 'Decline',
                                onTap: _onReject,
                              ),

                              const SizedBox(width: 40),

                              // ── Accept (green) ────────────────────────
                              _CallActionButton(
                                icon: widget.callType == 'video'
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: const Color(0xFF43A047),
                                shadowColor: const Color(0x9943A047),
                                label: 'Accept',
                                onTap: _onAccept,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
// Pulsing avatar with purple gradient ring
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
          // Outer pulse ring
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

          // Purple gradient ring
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

          // White gap
          Container(
            width: 98,
            height: 98,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // Avatar image
          ClipOval(
            child: SizedBox(width: 92, height: 92, child: _buildAvatarImage()),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    final resolvedUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? (avatarUrl!.startsWith('http')
              ? avatarUrl!
              : '${Constants.imageUrl}$avatarUrl')
        : avatarUrl;
    return AvatarHelper.widget(resolvedUrl, fit: BoxFit.cover);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated circle action button (Accept / Reject) with label
// ─────────────────────────────────────────────────────────────────────────────
class _CallActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final String label;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.label,
    required this.onTap,
  });

  @override
  State<_CallActionButton> createState() => _CallActionButtonState();
}

class _CallActionButtonState extends State<_CallActionButton>
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
