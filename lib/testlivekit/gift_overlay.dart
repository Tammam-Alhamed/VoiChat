import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svga/flutter_svga.dart';

/// Data for a single gift that arrived over the socket.
class GiftEvent {
  final String giftName;
  final String svgaAsset; // e.g. assets/gifts/svga/hi.svga
  final String soundAsset; // e.g. assets/gifts/sounds/hi.mp3
  final int durationSeconds; // Hi = 3, Biano = 8, etc.
  final String senderName;

  GiftEvent({
    required this.giftName,
    required this.svgaAsset,
    required this.soundAsset,
    required this.durationSeconds,
    required this.senderName,
  });
}

/// Floats over the live video. Queues incoming gifts so they never overlap —
/// each gift plays its SVGA + sound for exactly `durationSeconds`, then the
/// next queued gift (if any) starts immediately.
class LiveGiftOverlay extends StatefulWidget {
  const LiveGiftOverlay({super.key});

  @override
  State<LiveGiftOverlay> createState() => LiveGiftOverlayState();
}

class LiveGiftOverlayState extends State<LiveGiftOverlay>
    with TickerProviderStateMixin {
  final List<GiftEvent> _queue = [];
  SVGAAnimationController? _svgaController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  GiftEvent? _current;
  bool _isPlaying = false;

  /// Call this from the live_gift_received socket listener.
  void enqueueGift(GiftEvent event) {
    _queue.add(event);
    _playNext();
  }

  Future<void> _playNext() async {
    if (_isPlaying || _queue.isEmpty || !mounted) return;
    _isPlaying = true;
    final event = _queue.removeAt(0);
    setState(() => _current = event);

    _svgaController?.dispose();
    _svgaController = SVGAAnimationController(vsync: this);

    try {
      final videoItem = event.svgaAsset.startsWith('http')
          ? await SVGAParser.shared.decodeFromURL(event.svgaAsset)
          : await SVGAParser.shared.decodeFromAssets(event.svgaAsset);
      if (!mounted) return;
      _svgaController!.videoItem = videoItem;
      _svgaController!.repeat();
    } catch (_) {
      // SVGA file missing/broken (asset or network) — still honor the
      // timed slot below so the audio (and queue timing) stays correct.
    }

    unawaited(
      _audioPlayer.play(
        event.soundAsset.startsWith('http')
            ? UrlSource(event.soundAsset)
            : AssetSource(event.soundAsset.replaceFirst('assets/', '')),
      ),
    );

    await Future.delayed(Duration(seconds: event.durationSeconds));
    if (!mounted) return;

    _svgaController?.stop();
    setState(() => _current = null);
    _isPlaying = false;
    _playNext(); // pick up anything that queued while this one was playing
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null || _svgaController?.videoItem == null) {
      return const SizedBox.shrink();
    }
    // Full screen width, anchored to the bottom (not a small centered
    // box) — this is the top-most layer of the room too, see where
    // LiveGiftOverlay is placed in the outer Stack in
    // test_designed_live_room.dart. Kept as a plain (non-Positioned)
    // Stack child, same as the original centered version — the parent
    // Stack already uses fit: StackFit.expand, so Align on its own
    // stretches to the full stack area without needing Positioned at all.
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: 260,
          child: SVGAImage(_svgaController!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
