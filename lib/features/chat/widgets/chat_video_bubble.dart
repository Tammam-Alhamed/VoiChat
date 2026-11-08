import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../viewmodel/chat_viewmodel.dart';

/// A chat bubble for a 'video' message: a thumbnail with a play button while
/// idle, swapping to real inline playback on tap. Deliberately simple — no
/// custom scrubber or fullscreen mode, just play/pause in place.
class ChatVideoBubble extends StatefulWidget {
  /// Local file path while the message is still sending, the server URL
  /// once it's confirmed.
  final String videoUrl;

  /// Preview image uploaded alongside the video. Null while sending (no
  /// server thumbnail yet) or for older messages sent before thumbnails
  /// existed.
  final String? thumbnailUrl;

  final bool isTemp;

  /// Compression/upload progress while isTemp is true.
  final MediaUploadProgress? progress;

  const ChatVideoBubble({
    super.key,
    required this.videoUrl,
    required this.isTemp,
    this.thumbnailUrl,
    this.progress,
  });

  @override
  State<ChatVideoBubble> createState() => _ChatVideoBubbleState();
}

class _ChatVideoBubbleState extends State<ChatVideoBubble> {
  static const double _size = 200;

  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isTemp || _isLoading) return;

    final existing = _controller;
    if (existing != null) {
      setState(() {
        if (existing.value.isPlaying) {
          existing.pause();
          _isPlaying = false;
        } else {
          existing.play();
          _isPlaying = true;
        }
      });
      return;
    }

    setState(() => _isLoading = true);

    final controller = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));

    try {
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_onControllerTick);
      setState(() {
        _controller = controller;
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onControllerTick() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final value = controller.value;
    final finished =
        value.duration > Duration.zero && value.position >= value.duration;
    if (finished && _isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showPreview = controller == null || !controller.value.isInitialized;

    return GestureDetector(
      onTap: _handleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (!showPreview)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              else if (widget.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black87),
                )
              else
                Container(color: Colors.black87),

              if (widget.isTemp)
                _ProgressOverlay(progress: widget.progress)
              else if (showPreview)
                Container(
                  color: Colors.black.withOpacity(0.15),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 54,
                          ),
                  ),
                )
              else if (!_isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  final MediaUploadProgress? progress;

  const _ProgressOverlay({this.progress});

  @override
  Widget build(BuildContext context) {
    final value = progress?.value ?? 0.0;
    final label = progress?.phase == 'uploading' ? 'Uploading…' : 'Compressing…';

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
                value: value > 0 ? value : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
