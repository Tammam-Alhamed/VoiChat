import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/constants.dart';

import '../app/di/injection_container.dart';
import '../core/network/service_helper.dart';
import '../core/helpers/store_helper.dart';
import '../core/helpers/toast_helper.dart';
import '../core/helpers/avatar_helper.dart';
import '../core/utils/api_status.dart';
import '../features/profile/state/target_profile_provider.dart';
import 'test_designed_live_room.dart';
import 'live_goal.dart';
import 'live_premium.dart';
import 'premium_join_screen.dart';

/// Full-screen "Stream Ended" panel shown when the broadcaster ends the
/// live session. Shows the host's photo/name with a real Follow button,
/// then counts down and auto-advances into the next real active live
/// stream (fetched from GET /v1/live/active), or returns home if there
/// isn't one.
class StreamEndedOverlay extends StatefulWidget {
  final String hostId;
  final String hostName;
  final String? hostImage;

  /// The live stream that just ended — excluded when picking "what's next".
  final String currentLiveId;

  const StreamEndedOverlay({
    super.key,
    required this.hostId,
    required this.hostName,
    required this.currentLiveId,
    this.hostImage,
  });

  @override
  State<StreamEndedOverlay> createState() => _StreamEndedOverlayState();
}

class _StreamEndedOverlayState extends State<StreamEndedOverlay> {
  final _serviceHelper = sl<ServiceHelper>();
  final _storeHelper = sl<StoreHelper>();

  static const int _countdownSeconds = 8;
  int _secondsLeft = _countdownSeconds;
  Timer? _timer;

  bool _lookingUpNext = true;
  bool _joining = false;

  // The next live to jump to, once found. Null + !_lookingUpNext means
  // "checked, nothing else live right now" → countdown just goes home.
  Map<String, dynamic>? _nextLive;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TargetProfileProvider>();
      provider.reset(userId: widget.hostId);
      provider.getProfile(userId: widget.hostId);
    });

    _findNextLive();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _advance();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Looks up a real next stream to advance to via the existing, already
  /// live "active streams" endpoint (ordered by viewer count server-side).
  Future<void> _findNextLive() async {
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/live/active?page=1&limit=10',
        token: token,
      );

      if (response is! Success) {
        if (mounted) setState(() => _lookingUpNext = false);
        return;
      }

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      final List<dynamic> list = (body['data'] as List<dynamic>? ?? []);
      final candidate = list.cast<Map<String, dynamic>>().firstWhere(
        (row) => row['id'].toString() != widget.currentLiveId,
        orElse: () => {},
      );

      if (!mounted) return;
      setState(() {
        _nextLive = candidate.isEmpty ? null : candidate;
        _lookingUpNext = false;
      });
    } catch (e) {
      if (kDebugMode) print('StreamEndedOverlay._findNextLive error: $e');
      if (mounted) setState(() => _lookingUpNext = false);
    }
  }

  /// Called when the countdown hits zero or the user taps "Watch Now".
  Future<void> _advance() async {
    if (_joining) return;

    final next = _nextLive;
    if (next == null) {
      Get.back(); // No other live right now — just leave the stream screen.
      return;
    }

    setState(() => _joining = true);

    final liveId = next['id'].toString();
    final hostRow = next['User'] as Map<String, dynamic>?;

    final response = await _serviceHelper.postHelper(
      target: '/v1/live/$liveId/join',
      token: _storeHelper.getAccessToken(),
      data: const {},
    );

    if (!mounted) return;

    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          // Next live is Premium and not paid yet → "Join now" screen.
          if (openPremiumGateIfRequired(
            data,
            liveId: liveId,
            hostId: (hostRow?['id'] ?? next['user_id'] ?? '').toString(),
            hostName: hostRow?['name']?.toString(),
            hostImage: hostRow?['profile_image']?.toString(),
            streamTitle: next['title']?.toString(),
            replace: true,
          )) {
            return;
          }
          final liveStream = data['liveStream'];
          final tokenVal = data['token'];
          final roomName = data['roomName'] ?? liveStream['room_name'];

          Get.off(
            () => LiveStreamingScreen(
              token: tokenVal,
              roomName: roomName,
              host: Constants.sfu,
              isHost: false,
              liveId: liveId,
              hostId: (hostRow?['id'] ?? next['user_id'] ?? '').toString(),
              streamTitle: next['title']?.toString() ?? 'Live Stream',
              hostName: hostRow?['name']?.toString() ?? 'Host',
              hostImage: hostRow?['profile_image']?.toString(),
              initialGoal: LiveGoal.fromJson(data['goal']),
              initialGiftsTotal:
                  num.tryParse('${liveStream['total_gifts_value']}') ?? 0,
              initialPremium: LivePremiumInfo.fromJson(data['premium']),
            ),
          );
          return;
        }
      } catch (e) {
        if (kDebugMode) print('StreamEndedOverlay._advance parse error: $e');
      }
    }

    // Join failed (stream just ended, race condition, network, etc.) — fail
    // gracefully back to home instead of leaving the user stuck here.
    if (mounted) {
      ToastHelper.showErrorToast(message: 'That stream is no longer available');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<TargetProfileProvider>();
    final hasHostProfile =
        profileProvider.targetId == widget.hostId &&
        profileProvider.profile != null;
    final isFollowingHost = hasHostProfile
        ? profileProvider.profile!.isFollowing
        : false;

    final nextLabel = _lookingUpNext
        ? 'Looking for the next stream…'
        : _nextLive != null
        ? 'Next stream in $_secondsLeft…'
        : 'Going home in $_secondsLeft…';

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: AvatarHelper.resolve(widget.hostImage),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Stream Ended',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hostName,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  if (!isFollowingHost)
                    GestureDetector(
                      onTap: widget.hostId.isEmpty
                          ? null
                          : () => context
                                .read<TargetProfileProvider>()
                                .followUser(userId: widget.hostId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3A54),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          profileProvider.followLoader ? '...' : '+ Follow',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Text(
                        'Following',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Text(
                    nextLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            Get.back();
                          },
                          child: const Text(
                            'Go Home',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B3EE8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed:
                              (_lookingUpNext || _joining || _nextLive == null)
                              ? null
                              : () {
                                  _timer?.cancel();
                                  _advance();
                                },
                          child: Text(
                            _joining ? 'Joining…' : 'Watch Now',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
