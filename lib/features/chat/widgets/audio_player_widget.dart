import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// A simple, WhatsApp-style voice message player: a play/pause button, a
/// slim seekable progress bar, and a duration label. Intentionally plain —
/// no waveform, no custom animation — so it's easy to read at a glance and
/// hard to break.
class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final bool isTemp;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.isTemp,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Source get _source => widget.url.startsWith('http')
      ? UrlSource(widget.url)
      : DeviceFileSource(widget.url);

  @override
  void initState() {
    super.initState();
    _attachListeners();
    // Nothing to preview until the file has actually finished uploading.
    if (!widget.isTemp) _loadSource();
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A voice bubble is first shown optimistically (isTemp: true, local
    // recording path, no player attached yet), then swapped in place for
    // the server-confirmed message once the upload finishes (isTemp turns
    // false, url becomes the real remote URL). Without this, that swap
    // never re-loaded the source, so the bubble kept showing "--:--" and a
    // silent, non-updating player until some unrelated later rebuild
    // happened to reset this widget's state from scratch.
    final justConfirmed = oldWidget.isTemp && !widget.isTemp;
    final urlChanged = oldWidget.url != widget.url;
    if (justConfirmed || urlChanged) {
      _loadSource();
    }
  }

  bool _listenersAttached = false;

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _loadSource() async {
    if (widget.isTemp) return;
    try {
      await _audioPlayer.setSource(_source);
    } catch (e) {
      debugPrint('Audio load error: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(_source);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _accent => widget.isMe ? Colors.white : const Color(0xFF6044FF);
  Color get _trackColor =>
      widget.isMe ? Colors.white.withOpacity(0.4) : Colors.black12;
  Color get _labelColor => widget.isMe ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    final durationMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds
        : 1;
    final positionMs = _position.inMilliseconds.clamp(0, durationMs);

    return SizedBox(
      width: 210,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.isTemp ? null : _togglePlayback,
            child: widget.isTemp
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: _accent,
                    size: 34,
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                min: 0,
                max: durationMs.toDouble(),
                value: positionMs.toDouble(),
                activeColor: _accent,
                inactiveColor: _trackColor,
                onChanged: widget.isTemp
                    ? null
                    : (value) =>
                          _audioPlayer.seek(Duration(milliseconds: value.toInt())),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.isTemp
                ? '--:--'
                : _format(_isPlaying ? _position : _duration),
            style: TextStyle(
              color: _labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
