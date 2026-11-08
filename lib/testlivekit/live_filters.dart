import 'package:flutter/material.dart';

/// Camera colour filters shared by the Go Live setup screen and the live
/// room, so a filter picked before going live carries over as-is.
///
/// Each filter is a translucent colour wash painted over the local camera
/// preview (see the note in LiveStreamingScreen for why it's an overlay and
/// not a ColorFilter). It only changes what the host sees locally.
class LiveFilters {
  LiveFilters._();

  static const String none = 'none';

  static const Map<String, String> labels = {
    'none': 'None',
    'desert': 'Desert',
    'peach': 'Peach',
    'plum': 'Plum',
    'clash': 'Clash',
  };

  static const Map<String, Color> tints = {
    'desert': Color(0x33FF7A6A), // rgba(255,122,106,0.2)
    'peach': Color(0x337E06FC), // rgba(126,6,252,0.2)
    'plum': Color(0x330085FF), // rgba(0,133,255,0.2)
    'clash': Color(0x66F95353), // rgba(249,83,83,0.4)
  };

  /// Null for 'none' (or an unknown id).
  static Color? tintFor(String id) => tints[id];
}
