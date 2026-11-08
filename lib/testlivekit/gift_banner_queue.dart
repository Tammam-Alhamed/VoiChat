import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/helpers/avatar_helper.dart';

/// One "someone sent a gift" event, as parsed off the `live_gift_received`
/// socket payload. [giftId] (falls back to [giftName] if the payload is
/// missing an id) is what combo-matches repeated sends of the same gift by
/// the same sender into a single banner instead of a new one each time.
class GiftBannerEvent {
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String giftId;
  final String giftName;
  final String giftImage;
  final num giftPrice;

  const GiftBannerEvent({
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.giftId,
    required this.giftName,
    required this.giftImage,
    required this.giftPrice,
  });

  String get matchKey => giftId.isNotEmpty ? giftId : giftName;
}

class _GiftSlot {
  final GiftBannerEvent event;
  int combo;
  bool visible; // flips true one frame after creation to trigger the
  // entrance slide/fade instead of popping in already-settled.
  bool fadingOut;
  bool bump; // brief scale punch on the gift icon/count when combo ticks up
  double comboRemainingFraction; // 1.0 -> 0.0 over the 5s combo window
  Timer? lifetimeTimer;
  Timer? comboRingTimer;

  _GiftSlot(this.event)
    : combo = 1,
      visible = false,
      fadingOut = false,
      bump = false,
      comboRemainingFraction = 1.0;
}

/// Manages the stacked "X sent a gift x3" banners shown to everyone in the
/// live room: up to [maxActive] shown at once, everything else waits in a
/// queue; repeated sends of the same gift by the same sender bump the
/// existing banner's combo count instead of spawning a new one; the
/// sender's own banner additionally gets a 5s "Combo" quick-resend button.
class GiftBannerQueue extends StatefulWidget {
  final String currentUserId;

  /// Fired when the current user taps their own Combo button — the parent
  /// is responsible for actually re-sending the gift (wallet deduction +
  /// socket emit); this widget only manages display/queueing, never money.
  final void Function(GiftBannerEvent event)? onComboTap;

  const GiftBannerQueue({
    super.key,
    required this.currentUserId,
    this.onComboTap,
  });

  @override
  State<GiftBannerQueue> createState() => GiftBannerQueueState();
}

class GiftBannerQueueState extends State<GiftBannerQueue> {
  static const _maxActive = 4;
  static const _lifetime = Duration(seconds: 5);
  static const _ringTick = Duration(milliseconds: 100);

  final List<_GiftSlot> _active = [];
  final List<GiftBannerEvent> _queue = [];

  /// Call this from the `live_gift_received` socket handler for every gift
  /// event — handles combo-matching, activating a free slot, or queueing.
  void enqueueGift(GiftBannerEvent event) {
    final existingIndex = _active.indexWhere(
      (s) =>
          !s.fadingOut &&
          s.event.senderId == event.senderId &&
          s.event.matchKey == event.matchKey,
    );

    if (existingIndex != -1) {
      _bumpCombo(_active[existingIndex]);
      return;
    }

    if (_active.length < _maxActive) {
      _activateSlot(event);
    } else {
      _queue.add(event);
    }
  }

  void _activateSlot(GiftBannerEvent event) {
    final slot = _GiftSlot(event);
    setState(() => _active.add(slot));

    // Start off-screen/invisible, then flip to visible a frame later so
    // the AnimatedSlide/AnimatedOpacity below actually animates in rather
    // than appearing already-settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => slot.visible = true);
    });

    _armLifetime(slot);
    if (event.senderId == widget.currentUserId) _armComboRing(slot);
  }

  void _bumpCombo(_GiftSlot slot) {
    setState(() {
      slot.combo += 1;
      slot.bump = true;
    });
    Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => slot.bump = false);
    });

    _armLifetime(slot);
    if (slot.event.senderId == widget.currentUserId) _armComboRing(slot);
  }

  void _armLifetime(_GiftSlot slot) {
    slot.lifetimeTimer?.cancel();
    slot.lifetimeTimer = Timer(_lifetime, () => _expireSlot(slot));
  }

  // Drives the countdown ring on the sender's own Combo button; resets on
  // every combo hit, per spec ("يُعاد احتساب الـ5 ثوانٍ بعد كل ضغطة").
  void _armComboRing(_GiftSlot slot) {
    slot.comboRingTimer?.cancel();
    slot.comboRemainingFraction = 1.0;

    final totalTicks = _lifetime.inMilliseconds ~/ _ringTick.inMilliseconds;
    var ticksLeft = totalTicks;

    slot.comboRingTimer = Timer.periodic(_ringTick, (timer) {
      ticksLeft -= 1;
      if (!mounted || slot.fadingOut || ticksLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => slot.comboRemainingFraction = ticksLeft / totalTicks);
    });
  }

  Future<void> _expireSlot(_GiftSlot slot) async {
    if (!mounted || slot.fadingOut) return;

    slot.comboRingTimer?.cancel();
    setState(() => slot.fadingOut = true);

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() => _active.remove(slot));

    if (_queue.isNotEmpty) {
      _activateSlot(_queue.removeAt(0));
    }
  }

  void _onComboTap(_GiftSlot slot) {
    widget.onComboTap?.call(slot.event);
  }

  @override
  void dispose() {
    for (final slot in _active) {
      slot.lifetimeTimer?.cancel();
      slot.comboRingTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 60, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _active.map(_buildSlot).toList(),
      ),
    );
  }

  Widget _buildSlot(_GiftSlot slot) {
    final isMine = slot.event.senderId == widget.currentUserId;

    return Padding(
      // Reserve headroom above the pill for the Combo button, which sits
      // "فوق الهدية المرسلة مباشرة" (directly above the sent gift).
      padding: EdgeInsets.only(top: isMine ? 40 : 0, bottom: 10),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        offset: slot.visible ? Offset.zero : const Offset(-1.3, 0),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: slot.fadingOut ? 350 : 200),
          opacity: slot.fadingOut ? 0.0 : (slot.visible ? 1.0 : 0.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildPill(slot),
              if (isMine && !slot.fadingOut)
                Positioned(
                  top: -40,
                  left: 8,
                  child: _ComboButton(
                    fraction: slot.comboRemainingFraction,
                    combo: slot.combo,
                    onTap: () => _onComboTap(slot),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(_GiftSlot slot) {
    final event = slot.event;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7247EF).withOpacity(0.85),
            const Color(0xFFB862E1).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: AvatarHelper.resolve(event.senderImage),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.senderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Send a ${event.giftName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 10),
          AnimatedScale(
            scale: slot.bump ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: event.giftImage.isEmpty
                ? const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 26,
                  )
                : CachedNetworkImage(
                    imageUrl: event.giftImage,
                    width: 28,
                    height: 28,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          AnimatedScale(
            scale: slot.bump ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Text(
              'x${slot.combo}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The round "Combo" quick-resend button with a depleting ring showing how
/// much of the 5s window is left — tapping it re-sends the same gift and
/// resets the window.
class _ComboButton extends StatelessWidget {
  final double fraction;
  final int combo;
  final VoidCallback onTap;

  const _ComboButton({
    required this.fraction,
    required this.combo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4C6B), Color(0xFFB6304A)],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Combo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'x$combo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
}
