import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/assets_manager.dart';

import '../app/di/injection_container.dart';
import '../core/network/service_helper.dart';
import '../core/helpers/store_helper.dart';
import '../core/utils/api_status.dart';
import '../core/network/socket_service.dart';
import '../core/helpers/toast_helper.dart';
import '../core/helpers/avatar_helper.dart';
import '../core/helpers/wallet_helper.dart';

import '../features/calls/state/calls_provider.dart';
import '../features/profile/state/target_profile_provider.dart';
import '../features/home/presentation/controllers/navigation_controller.dart';
import '../features/home/tabs/messages/ui/messages_tab.dart';
import 'gifts_bottom_sheet.dart';
import 'gift_overlay.dart';
import 'gift_banner_queue.dart';
import 'top_viewer_sheet.dart';
import 'ranking_sheet.dart';
import 'mini_profile_sheet.dart';
import 'stream_ended_overlay.dart';
import 'live_filters.dart';
import 'live_goal.dart';
import 'live_goal_widgets.dart';
import 'live_premium.dart';
import 'premium_entry_gift_sheet.dart';
import 'premium_join_screen.dart';

import '../features/session/presentation/controllers/session_controller.dart';

class LiveStreamingScreen extends StatefulWidget {
  /// LiveKit join token
  final String token;

  /// LiveKit room name
  final String roomName;

  /// LiveKit server URL (e.g. wss://...)
  final String host;

  /// true = broadcaster, false = viewer
  final bool isHost;

  /// Backend live stream ID (for socket rooms & API)
  final String liveId;

  /// Host's user ID — needed to send them gifts (POST /wallet/gifts/send)
  /// and to open the Daily Ranking panel scoped to this host. Empty when
  /// unavailable (falls back to disabling those actions gracefully).
  final String hostId;

  /// Display title
  final String streamTitle;

  /// Host display name
  final String hostName;

  /// Host profile image URL (optional)
  final String? hostImage;

  /// The live session's goal as returned by start/join/resume. The screen
  /// re-fetches it from the server on open, on app resume and after a
  /// socket reconnect, so this is only the first paint. Null = no goal.
  final LiveGoal? initialGoal;

  /// Gift value already received when joining (viewers joining mid-stream),
  /// so the goal progress doesn't start from 0.
  final num initialGiftsTotal;

  /// Premium state from start/join/resume (re-fetched on open).
  final LivePremiumInfo? initialPremium;

  /// Host's "Call off" state for this live (restored when resuming).
  final bool initialCallsOff;

  /// Camera filter picked on the setup screen (host only).
  final String initialFilterId;

  const LiveStreamingScreen({
    super.key,
    required this.token,
    required this.roomName,
    required this.host,
    required this.isHost,
    required this.liveId,
    this.hostId = '',
    this.streamTitle = "Live Stream",
    this.hostName = "Host",
    this.hostImage,
    this.initialGoal,
    this.initialGiftsTotal = 0,
    this.initialFilterId = LiveFilters.none,
    this.initialPremium,
    this.initialCallsOff = false,
  });

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with WidgetsBindingObserver {
  final _serviceHelper = sl<ServiceHelper>();
  final _storeHelper = sl<StoreHelper>();
  final _socket = sl<SocketService>();

  // --- LiveKit state ---
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _hostVideoTrack;

  bool _isMicMuted = false;

  // Host's "Call off": while true nobody can call them (enforced by the
  // server). Shown as a red icon in the top bar, like the muted mic.
  late bool _callsOff = widget.initialCallsOff;
  bool _callsOffBusy = false;
  bool _isCameraOff = false;
  bool _isConnecting = true;
  bool _isCleanedUp = false;
  String? _connectionError;
  int _viewerCount = 0;
  bool _isFrontCamera = true;

  // Captured the moment this screen mounts — used to show a real elapsed
  // duration ("1h 20m") on the End Stream sheet, since the backend doesn't
  // hand back a started_at timestamp to this screen.
  final DateTime _liveStartedAt = DateTime.now();

  // Running total of coins/diamonds this live session has earned (host
  // only) — kept in sync via the liveTotalGiftsValue field that rides
  // along on every live_gift_received broadcast. Real backend-derived
  // number, not a local guess.
  late num _sessionDiamonds = widget.initialGiftsTotal;

  // Live goal of THIS session (server is the source of truth — see
  // _loadGoal and the live_goal_* socket events). Null = no goal.
  late LiveGoal? _goal = widget.initialGoal;
  bool _showGoalAchieved = false;
  Timer? _goalAchievedTimer;
  StreamSubscription<void>? _socketReconnectSub;

  // Premium (entry gift) state of this live session — see _loadPremium and
  // the live_premium_* socket events.
  late LivePremiumInfo _premium = widget.initialPremium ?? LivePremiumInfo.off;
  bool _leavingForPremiumGate = false;

  // Recent-activity avatars for the top bar's small avatar row: gifters
  // (most recent first, with a gift-count badge) always take priority;
  // recent joiners fill in when nobody's gifted yet. _allGifterIds tracks
  // every distinct gifter for the whole session (not just the ones
  // currently visible) — that's what the trailing count next to the
  // avatars shows.
  final List<_AvatarActivity> _gifterAvatars = [];
  final List<_AvatarActivity> _joinerAvatars = [];
  final Set<String> _allGifterIds = {};

  // Local color filter applied to the host's own camera preview — a real,
  // rendered effect, though it only affects what the host sees locally,
  // not the frames actually published to viewers.
  late String _activeFilterId = widget.initialFilterId;

  // Whether the inline filter picker (see _buildFilterPanel) is open. It
  // replaces the bottom toolbar while open, same pattern as _isChatVisible.
  bool _isFilterPanelOpen = false;

  // --- Chat state ---
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _liveChats = [];
  bool _isChatVisible = true;
  int _unreadChatCount = 0;

  // True once the host has ended the broadcast (viewer side only) — swaps
  // the whole screen body for the real StreamEndedOverlay instead of a
  // dead-end dialog.
  bool _streamEnded = false;

  // --- Gift overlay ---
  final GlobalKey<LiveGiftOverlayState> _giftOverlayKey =
      GlobalKey<LiveGiftOverlayState>();
  final GlobalKey<GiftBannerQueueState> _giftBannerQueueKey =
      GlobalKey<GiftBannerQueueState>();

  // Remembers every gift the current user has actually sent, keyed by
  // gift id, so a tap on the Combo quick-resend button can look up the
  // full GiftItem (svga/sound/price/etc.) needed to send it again.
  final Map<String, GiftItem> _sentGiftsById = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLiveKit();
    _initSocket();
    _loadCommentsHistory();
    _loadGoal();
    _loadPremium();

    // After a temporary connection drop: silently re-enter this session's
    // socket room and re-sync the goal (progress + status) from the server.
    _socketReconnectSub = _socket.reconnectedStream.listen((_) {
      if (_isCleanedUp) return;
      _socket.emit('rejoin_live_chat', {'liveStreamId': widget.liveId});
      _loadGoal();
      _loadPremium();
    });

    // Preload the host's real follow state for the viewer-side top bar's
    // Follow pill (and the mini profile sheet reuses the exact same shared
    // provider instance, so both stay in sync automatically).
    if (!widget.isHost && widget.hostId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<TargetProfileProvider>();
        provider.reset(userId: widget.hostId);
        provider.getProfile(userId: widget.hostId);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupLive();
    super.dispose();
  }

  // Best-effort extra signal for when the app is torn down without ever
  // reaching this widget's dispose() — e.g. the OS reclaiming a
  // backgrounded app's process. NOT relied upon as the actual fix (Android
  // gives no guaranteed callback when the user force-swipes the app away
  // from the recent-apps switcher — dispose()/this callback simply never
  // fire in that case). The real fix for that scenario lives on the
  // server: the socket's 'disconnect' event always fires when the process
  // dies, and the backend now auto-ends an abandoned live stream ~45s
  // after that (see nodejs_server/src/sockets/index.js), plus startLive()
  // self-heals a stale row even if that somehow didn't run. This handler
  // just makes the graceful-backgrounding case a little faster/cleaner
  // when the OS does inform us.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && !_isCleanedUp) {
      _cleanupLive();
    } else if (state == AppLifecycleState.resumed && !_isCleanedUp) {
      // Back from the background: progress may have moved meanwhile.
      _loadGoal();
    }
  }

  // ==========================================
  // LiveKit Connection
  // ==========================================
  Future<void> _initLiveKit() async {
    try {
      _room = Room();
      _listener = _room!.createListener();

      // Track subscribed (for viewers receiving host video)
      _listener!.on<TrackSubscribedEvent>((event) {
        if (event.track.kind == TrackType.VIDEO) {
          setState(() => _hostVideoTrack = event.track as VideoTrack);
        }
      });

      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (event.track.kind == TrackType.VIDEO) {
          setState(() => _hostVideoTrack = null);
        }
      });

      if (kDebugMode) {
        print("Connecting to LiveKit: ${widget.host} room: ${widget.roomName}");
      }
      await _room!.connect(widget.host, widget.token);

      if (widget.isHost) {
        await _room!.localParticipant!.setCameraEnabled(true);
        await _room!.localParticipant!.setMicrophoneEnabled(true);
      } else {
        // Scan already-published tracks
        for (var participant in _room!.remoteParticipants.values) {
          for (var pub in participant.videoTrackPublications) {
            if (pub.subscribed && pub.track != null) {
              setState(() => _hostVideoTrack = pub.track as VideoTrack);
            }
          }
        }
      }

      setState(() => _isConnecting = false);
    } catch (e) {
      if (kDebugMode) print("LiveKit connection error: $e");
      setState(() {
        _isConnecting = false;
        _connectionError = "Failed to connect: $e";
      });
    }
  }

  // ==========================================
  // Socket Events
  // ==========================================
  void _initSocket() {
    _socket.emit('join_live_chat', {'liveStreamId': widget.liveId});

    // --- Live goal (progress/status pushed by the server) ---
    _socket.on('live_goal_updated', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      if (parsed is! Map ||
          parsed['liveSessionId']?.toString() != widget.liveId) {
        return;
      }
      if (!mounted) return;
      setState(() => _goal = LiveGoal.fromJson(parsed['goal']));
    });

    // --- Premium (entry gift) ---
    _socket.on('live_premium_updated', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      if (parsed is! Map ||
          parsed['liveSessionId']?.toString() != widget.liveId) {
        return;
      }
      if (!mounted) return;
      final info = LivePremiumInfo.fromJson(parsed) ?? LivePremiumInfo.off;
      setState(() => _premium = info.copyWith(hasAccess: _premium.hasAccess));
      // Premium just turned on: a viewer who hasn't paid must send the
      // entry gift to keep watching (the server also takes them out of the
      // video room).
      if (!widget.isHost && info.isPremium) _loadPremium();
    });

    _socket.on('live_premium_joined', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      if (parsed is! Map ||
          parsed['liveSessionId']?.toString() != widget.liveId) {
        return;
      }
      if (!mounted) return;
      // The entry gift itself arrives as a normal 'live_gift_received'
      // (animation, banner, earnings) — this only adds the "joined" line.
      final user = parsed['user'] is Map ? parsed['user'] as Map : const {};
      final giftJson = parsed['gift'];
      final gift = giftJson is Map<String, dynamic>
          ? GiftItem.fromJson(giftJson)
          : null;
      final liveTotal = num.tryParse('${parsed['liveTotalGiftsValue']}');
      setState(() {
        _liveChats.add({
          'name': user['name']?.toString() ?? 'Someone',
          'message': 'joined Premium with ${gift?.name ?? 'a gift'} 💎',
          'badge': null,
          'isJoin': false,
          'image': user['profileImage'],
          'vip': 0,
          'is_verified': false,
        });
        if (!_isChatVisible) _unreadChatCount++;
        if (liveTotal != null) _sessionDiamonds = liveTotal;
      });
      _scrollToBottom();
    });

    _socket.on('live_goal_achieved', (data) {
      final parsed = data is String ? jsonDecode(data) : data;
      if (parsed is! Map ||
          parsed['liveSessionId']?.toString() != widget.liveId) {
        return;
      }
      final goal = LiveGoal.fromJson(parsed['goal']);
      if (!mounted || goal == null) return;
      setState(() => _goal = goal);
      _celebrateGoal();
    });

    _socket.on('new_comment', (data) {
      try {
        final comment = data is String ? jsonDecode(data) : data;
        final user = comment['user'] ?? {};
        setState(() {
          _liveChats.add({
            'name': user['name'] ?? 'User',
            'message': comment['content'] ?? '',
            'badge': null,
            'isJoin': false,
            'image': user['profile_image'],
            'vip': user['vip_member'] == false ? 0 : user['vip_member'],
            'is_verified': user['is_verified'],
          });
          if (!_isChatVisible) _unreadChatCount++;
        });
        _scrollToBottom();
      } catch (e) {
        if (kDebugMode) print("Error parsing new_comment: $e");
      }
    });

    _socket.on('live_ended', (data) {
      if (!widget.isHost && mounted) {
        _onLiveEndedByBroadcaster();
      }
    });

    _socket.on('viewer_joined', (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : data;
        final name = parsed['name'] ?? 'Someone';
        final profileImage = parsed['profileImage'];
        final count = parsed['viewerCount'];
        // The server fires this same event for the host joining their own
        // room (join_live_chat is emitted unconditionally by both roles),
        // so without this check the host would see "Mohammed Joined" about
        // themselves. userId is in the payload (see nodejs_server's
        // socket join_live_chat handler) — when it matches the host, this
        // is the host's own connection, not an actual viewer.
        final joinedUserId = parsed['userId']?.toString();
        final isSelfStart =
            widget.isHost &&
            joinedUserId != null &&
            joinedUserId == widget.hostId;
        setState(() {
          _viewerCount = count is int
              ? count
              : int.tryParse(count.toString()) ?? _viewerCount;
          if (isSelfStart) {
            _liveChats.add({
              'name': 'You',
              'message': 'started a live stream',
              'badge': null,
              'isJoin': true,
              'isSelfStart': true,
              'image': profileImage,
              'vip': 0,
              'is_verified': false,
            });
          } else {
            _liveChats.add({
              'name': name,
              'message': 'Joined',
              'badge': null,
              'isJoin': true,
              'image': profileImage,
              'vip': parsed['vip_member'] == false ? 0 : parsed['vip_member'],
              'is_verified': parsed['is_verified'],
            });

            // Recent-joiner avatar fallback for the top bar's activity
            // row — only shown when that person hasn't already gifted
            // (gifters take priority there, per client spec).
            if (joinedUserId != null &&
                joinedUserId.isNotEmpty &&
                !_gifterAvatars.any((a) => a.userId == joinedUserId)) {
              _joinerAvatars.removeWhere((a) => a.userId == joinedUserId);
              _joinerAvatars.insert(
                0,
                _AvatarActivity(userId: joinedUserId, image: profileImage),
              );
              if (_joinerAvatars.length > 3) {
                _joinerAvatars.removeRange(3, _joinerAvatars.length);
              }
            }
          }
          if (!_isChatVisible) _unreadChatCount++;
        });
        _scrollToBottom();
      } catch (e) {
        if (kDebugMode) print("Error parsing viewer_joined: $e");
      }
    });

    _socket.on('viewer_left', (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : data;
        final count = parsed['viewerCount'];
        setState(() {
          _viewerCount = count is int
              ? count
              : int.tryParse(count.toString()) ?? _viewerCount;
        });
      } catch (e) {
        if (kDebugMode) print("Error parsing viewer_left: $e");
      }
    });

    // --- Gift received (broadcast to everyone in the live room) ---
    _socket.on('live_gift_received', (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : data;
        final gift = parsed['gift'] ?? {};
        final sender = parsed['sender'] ?? {};

        final durationSeconds = gift['duration'] is int
            ? gift['duration'] as int
            : int.tryParse('${gift['duration']}') ?? 3;

        _giftOverlayKey.currentState?.enqueueGift(
          GiftEvent(
            giftName: gift['name'] ?? '',
            svgaAsset: gift['svga'] ?? '',
            soundAsset: gift['sound'] ?? '',
            durationSeconds: durationSeconds,
            senderName: sender['name'] ?? 'Someone',
          ),
        );

        // Queued combo banner: everyone in the room sees who's sending
        // what, with repeats of the same gift by the same sender bumping
        // a combo count instead of stacking a fresh banner each time.
        _giftBannerQueueKey.currentState?.enqueueGift(
          GiftBannerEvent(
            senderId: sender['id']?.toString() ?? '',
            senderName: sender['name'] ?? 'Someone',
            senderImage: sender['profileImage'],
            giftId: gift['id']?.toString() ?? '',
            giftName: gift['name'] ?? '',
            giftImage: gift['imageUrl'] ?? '',
            giftPrice: gift['price'] is num
                ? gift['price'] as num
                : num.tryParse('${gift['price']}') ?? 0,
          ),
        );

        // Real-time diamond counter — every gift in this room is sent to
        // the host, so any client that IS the host can trust this number.
        final liveTotal = num.tryParse('${gift['liveTotalGiftsValue']}');

        final senderId = sender['id']?.toString() ?? '';
        final senderImage = sender['profileImage']?.toString();

        setState(() {
          _liveChats.add({
            'name': sender['name'] ?? 'Someone',
            'message': 'sent ${gift['name'] ?? 'a gift'} 🎁',
            'badge': null,
            'isJoin': false,
            'image': sender['profileImage'],
            'vip': 0,
            'is_verified': false,
          });
          if (!_isChatVisible) _unreadChatCount++;
          // Everyone in the room sees the same running total, not just the
          // host — this drives the gift-progress pill/bar for viewers too.
          if (liveTotal != null) {
            _sessionDiamonds = liveTotal;
          }

          // Recent-activity avatars (top row, viewer's own top bar): a
          // gifter always jumps to the front, bumping their badge count;
          // see _joinerAvatars for the "nobody's gifted yet" fallback.
          if (senderId.isNotEmpty) {
            _allGifterIds.add(senderId);
            final existingIndex = _gifterAvatars.indexWhere(
              (a) => a.userId == senderId,
            );
            if (existingIndex != -1) {
              final existing = _gifterAvatars.removeAt(existingIndex);
              existing.giftCount += 1;
              _gifterAvatars.insert(0, existing);
            } else {
              _gifterAvatars.insert(
                0,
                _AvatarActivity(
                  userId: senderId,
                  image: senderImage,
                  giftCount: 1,
                ),
              );
            }
            if (_gifterAvatars.length > 3) {
              _gifterAvatars.removeRange(3, _gifterAvatars.length);
            }
            _joinerAvatars.removeWhere((a) => a.userId == senderId);
          }
        });
        _scrollToBottom();
      } catch (e) {
        if (kDebugMode) print("Error parsing live_gift_received: $e");
      }
    });
  }

  Future<void> _loadCommentsHistory() async {
    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/${widget.liveId}/comments?page=1&limit=50',
      token: token,
    );

    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final rawData = body['data']['data'] ?? body['data'];
          if (rawData is List) {
            setState(() {
              _liveChats.clear();
              _liveChats.addAll(
                rawData
                    .map((c) {
                      final user = c['user'] ?? {};
                      return {
                        'name': user['name'] ?? 'User',
                        'message': c['content'] ?? '',
                        'badge': null,
                        'isJoin': false,
                        'image': user['profile_image'],
                      };
                    })
                    .toList()
                    .reversed,
              );
            });
            _scrollToBottom();
          }
        }
      } catch (e) {
        if (kDebugMode) print("Error loading comments history: $e");
      }
    }
  }

  // ==========================================
  // Viewers list (GET /v1/live/:liveId/viewers)
  // ==========================================
  Future<List<Map<String, dynamic>>> _fetchLiveViewers() async {
    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/${widget.liveId}/viewers',
      token: token,
    );

    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        if (kDebugMode) print("Error parsing viewers: $e");
      }
    }
    return [];
  }

  Future<void> _openTopViewers() async {
    final viewers = await _fetchLiveViewers();
    if (!mounted) return;
    showTopViewersBottomSheet(context, viewers: viewers);
  }

  String? _resolveViewerImage(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return null;
    return s.startsWith('http') ? s : AssetsManager.getNetworkImagePath(s);
  }

  /// "Start 1:1" — reuses the app's real, already-working 1:1 video call
  /// system (CallsProvider), same as the plain call button elsewhere.
  /// Host picks a viewer from the real (now-fixed) live viewer list;
  /// viewer just calls the host directly. This actually leaves the live
  /// LiveKit room connected in the background and pushes the standard
  /// call screen on top — there is no separate "stay live + add guest"
  /// mode anywhere in this codebase to build on.
  Future<void> _openStart1on1() async {
    final callsProvider = context.read<CallsProvider>();
    if (callsProvider.state != CallState.idle) {
      ToastHelper.showInfoToast(message: 'You already have a call in progress');
      return;
    }

    if (!widget.isHost) {
      if (widget.hostId.isEmpty) {
        ToastHelper.showErrorToast(
          message: 'Unable to start a call: host unknown',
        );
        return;
      }
      await callsProvider.initiateCall(
        receiverId: widget.hostId,
        receiverName: widget.hostName,
        receiverImage: widget.hostImage,
      );
      return;
    }

    final viewers = await _fetchLiveViewers();
    if (!mounted) return;
    if (viewers.isEmpty) {
      ToastHelper.showInfoToast(message: 'No viewers to invite right now');
      return;
    }

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Start 1:1 with a viewer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: viewers.length,
                itemBuilder: (c, i) {
                  final v = viewers[i];
                  final img = _resolveViewerImage(v['profile_image']);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: AvatarHelper.resolve(img),
                    ),
                    title: Text(
                      v['name']?.toString() ?? 'Viewer',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.videocam,
                      color: Color(0xFF8B3EE8),
                    ),
                    onTap: () => Navigator.pop(ctx, v),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    await callsProvider.initiateCall(
      receiverId: picked['userId']?.toString() ?? '',
      receiverName: picked['name']?.toString() ?? 'Viewer',
      receiverImage: _resolveViewerImage(picked['profile_image']),
    );
  }

  /// "Call off" — hangs up whatever 1:1 call is currently outgoing/active
  /// (started via _openStart1on1), if any.
  /// "Call off" switch: stop / start receiving calls during this live.
  Future<void> _toggleCallsOff() async {
    if (!widget.isHost || _callsOffBusy) return;
    final turnOff = !_callsOff;
    setState(() {
      _callsOff = turnOff; // show it right away
      _callsOffBusy = true;
    });

    final response = await _serviceHelper.postHelper(
      target: '/v1/live/${widget.liveId}/calls-off',
      token: _storeHelper.getAccessToken(),
      data: {'off': turnOff},
    );
    if (!mounted) return;

    if (response is Success) {
      setState(() => _callsOffBusy = false);
      ToastHelper.showInfoToast(
        message: turnOff
            ? 'Calls are off — no one can call you'
            : 'Calls are on',
      );
    } else {
      setState(() {
        _callsOff = !turnOff; // undo
        _callsOffBusy = false;
      });
      ToastHelper.showErrorToast(
        message: response is Failure
            ? response.errorResponse.toString()
            : "Couldn't change call setting",
      );
    }
  }

  /// Real show/hide of the chat panel — kept for internal state bookkeeping,
  /// but nothing in the UI calls this anymore (see _openPrivateMessages).
  void _toggleChatVisible() {
    setState(() {
      _isChatVisible = !_isChatVisible;
      if (_isChatVisible) _unreadChatCount = 0;
    });
  }

  /// The toolbar's "Chat" button — per the Figma design, this opens the
  /// user's private conversations (the same Messages list used elsewhere in
  /// the app), not a toggle for the on-screen live comments feed (those
  /// stay visible the whole time, same as Figma). Pushed as a normal route
  /// so the back button returns here to the live stream.
  void _openPrivateMessages() {
    // MessagesTab's own entrance animation only plays when
    // NavigationController reports its tab (index 1) as active, and Home's
    // bottom nav should reflect Messages as selected whenever the user
    // does eventually navigate back there — so keep that state in sync.
    Get.find<NavigationController>().updateIndex(1);
    Get.to(() => const MessagesTab());
  }

  void _scrollToBottom() {
    // The chat list renders with reverse: true (see its ListView.builder)
    // so it stays hugged to the bottom with new messages growing upward,
    // like a normal chat UI. With reverse: true, offset 0 IS the visual
    // bottom/newest-message end — not maxScrollExtent, which would be the
    // oldest message, at the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onLiveEndedByBroadcaster() {
    if (!mounted) return;
    // Replace the live UI with the real Stream Ended screen (host photo,
    // real Follow button, countdown into the next active live) instead of
    // a dead-end "OK" dialog.
    setState(() => _streamEnded = true);
  }

  // ==========================================
  // Controls
  // ==========================================
  Future<void> _sendComment() async {
    final content = _chatController.text.trim();
    if (content.isEmpty) return;
    _chatController.clear();

    final token = _storeHelper.getAccessToken();
    await _serviceHelper.postHelper(
      target: '/v1/live/${widget.liveId}/comments',
      token: token,
      data: {'content': content},
    );
  }

  /// Deducts coins via the real wallet endpoint first, then only emits the
  /// live socket event (which drives the on-screen SVGA/sound overlay and
  /// the receiver's toast) once the deduction actually succeeds.
  Future<void> _sendGift(GiftItem gift) async {
    final user = Get.find<SessionController>().session!.user!;

    if (widget.hostId.isEmpty) {
      ToastHelper.showErrorToast(message: 'Unable to send gift: host unknown');
      return;
    }

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.postHelper(
      target: '/v1/wallet/gifts/send',
      token: token,
      data: {
        'receiverId': widget.hostId,
        'giftId': gift.id,
        'context': 'live',
        'contextId': widget.liveId,
      },
    );

    if (response is Failure) {
      // errorResponse is already the plain message string extracted by
      // ServiceHelper (e.g. "Insufficient balance to send this gift").
      final message = response.errorResponse?.toString().isNotEmpty == true
          ? response.errorResponse.toString()
          : 'Failed to send gift';
      ToastHelper.showErrorToast(message: message);
      return;
    }

    // Success: refresh the local wallet balance so the pill in the ranking
    // bar reflects the new total immediately, then broadcast the gift.
    num? liveTotalGiftsValue;
    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final newBalance = body['data']?['newBalance']?.toString();
        if (newBalance != null && mounted) {
          Get.find<SessionController>().session!.user!.walletBalance =
              newBalance;
          setState(() {});
        }
        liveTotalGiftsValue = num.tryParse(
          '${body['data']?['liveTotalGiftsValue']}',
        );
      } catch (_) {
        // Balance refresh is best-effort; ignore parse issues.
      }
    }

    // Remembered so a later tap on the Combo quick-resend button (see
    // GiftBannerQueue.onComboTap) can look this exact gift back up by id.
    _sentGiftsById[gift.id] = gift;

    _socket.emit('send_live_gift', {
      'liveStreamId': widget.liveId,
      'gift': {
        'id': gift.id,
        'name': gift.name,
        'svga': gift.svga,
        'sound': gift.sound,
        'price': gift.price,
        'duration': gift.durationSeconds,
        'imageUrl': gift.imageUrl,
        // Rides along so the host's own client (which also receives this
        // broadcast back) can update its real-time diamond counter.
        if (liveTotalGiftsValue != null)
          'liveTotalGiftsValue': liveTotalGiftsValue,
      },
      'sender': {
        'id': user.id,
        'name': user.name,
        'profileImage': user.profileImage,
      },
    });
  }

  // Fired by GiftBannerQueue when the current user taps their own Combo
  // button — re-sends the exact same gift (fresh wallet deduction +
  // socket emit), which naturally bumps the existing banner's combo count
  // when it round-trips back through live_gift_received.
  void _onComboResend(GiftBannerEvent event) {
    final gift = _sentGiftsById[event.giftId];
    if (gift == null) return;
    _sendGift(gift);
  }

  Future<void> _toggleMic() async {
    if (_room == null) return;
    try {
      final enabled = _isMicMuted;
      await _room!.localParticipant!.setMicrophoneEnabled(enabled);
      setState(() => _isMicMuted = !enabled);
    } catch (e) {
      if (kDebugMode) print("Error toggling mic: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_room == null) return;
    try {
      final enabled = _isCameraOff;
      await _room!.localParticipant!.setCameraEnabled(enabled);
      setState(() => _isCameraOff = !enabled);
    } catch (e) {
      if (kDebugMode) print("Error toggling camera: $e");
    }
  }

  /// Flips between front/rear camera using LiveKit's own
  /// `setCameraPosition`, which asks the platform for "the front camera" /
  /// "the back camera" directly instead of guessing which of
  /// `Hardware.instance.enumerateDevices()`'s entries is which by index.
  /// That index guess (`devices[0]`/`devices[1]`) is what caused the
  /// mirroring bug: on phones that enumerate more than 2 cameras (most
  /// modern phones report 3+ back cameras — wide/ultra-wide/telephoto —
  /// before the front one), the wrong physical camera got selected while
  /// `_isFrontCamera` was blindly toggled anyway, so the mirror flag drifted
  /// out of sync with whatever camera was actually on screen.
  Future<void> _switchCamera() async {
    if (_room == null || _isCameraOff) return;
    try {
      final publication =
          _room!.localParticipant?.videoTrackPublications.isNotEmpty == true
          ? _room!.localParticipant!.videoTrackPublications.first
          : null;

      if (publication?.track is LocalVideoTrack) {
        final track = publication!.track as LocalVideoTrack;
        final targetPosition = _isFrontCamera
            ? CameraPosition.back
            : CameraPosition.front;
        await track.setCameraPosition(targetPosition);

        // Read the camera position back from the track instead of assuming
        // the switch landed on what we asked for, so the mirror flag can
        // never drift from the real camera again.
        final options = track.currentOptions;
        final isFrontNow = options is CameraCaptureOptions
            ? options.cameraPosition == CameraPosition.front
            : targetPosition == CameraPosition.front;
        setState(() => _isFrontCamera = isFrontNow);
      }
    } catch (e) {
      if (kDebugMode) print("Error switching camera: $e");
      ToastHelper.showInfoToast(message: 'No other camera to switch to');
    }
  }

  // ==========================================
  // Camera filters
  // ==========================================
  // Matches the exact 5 filters from the Figma reference (None / Desert /
  // Peach / Plum / Clash), each a translucent colour wash over the live
  // feed — the same technique the design itself uses (a tint layer over a
  // photo). This is applied as a plain painted overlay on TOP of the video
  // (see _buildVideoBackground / _buildFilterChip), not as a ColorFilter on
  // the video texture itself: LiveKit's VideoTrackRenderer can render via a
  // native platform view depending on the device, and Flutter's
  // ColorFiltered/Opacity do not reliably affect platform-view content — an
  // overlay Container, being an ordinary Flutter-painted layer, always
  // shows regardless of how the video underneath is composited. That
  // reliability gap (tap registers, state updates, but nothing visibly
  // changes) is what the previous ColorFiltered-only version hit.
  // IMPORTANT caveat: this recolors the host's own local preview only — it
  // does not alter the actual frames published to viewers (that would need
  // native camera frame processing, out of scope here).
  // Shared with the Go Live setup screen (see live_filters.dart).
  static const Map<String, String> _filterLabels = LiveFilters.labels;

  Color? _tintFor(String id) => LiveFilters.tintFor(id); // null for 'none'

  // ==========================================
  // FILTER PANEL — inline live-filter picker that replaces the toolbar
  // while open (same pattern as the chat panel / _isChatVisible). Each
  // filter chip renders the host's own live camera feed tinted with that
  // filter, so what's shown is exactly what picking it will look like —
  // not a static icon. Matches the Figma reference: a horizontal row of
  // circular previews with a name label and a white selection ring, plus
  // a Filter/Beauty/Makeup category row underneath with a back arrow to
  // close the panel. Only "Filter" is wired to a real feature — Beauty and
  // Makeup aren't implemented, so they surface an honest "coming soon"
  // instead of a dead tap.
  // ==========================================
  Widget _buildFilterPanel() {
    final localTrack = _localCameraTrack();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: _filterLabels.entries
                  .map((e) => _buildFilterChip(e.key, e.value, localTrack))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isFilterPanelOpen = false),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterCategoryTab(
                      icon: SvgPicture.asset(
                        AssetsManager.liveFilter,
                        width: 20,
                        height: 20,
                      ),
                      label: 'Filter',
                      isActive: true,
                      onTap: () {},
                    ),
                    _buildFilterCategoryTab(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: 'Beauty',
                      isActive: false,
                      onTap: () => ToastHelper.showInfoToast(
                        message: 'Beauty is coming soon',
                      ),
                    ),
                    _buildFilterCategoryTab(
                      icon: const _LipstickIcon(),
                      label: 'Makeup',
                      isActive: false,
                      onTap: () => ToastHelper.showInfoToast(
                        message: 'Makeup is coming soon',
                      ),
                    ),
                  ],
                ),
              ),
              // Balances the back-arrow's width so the tab row still reads
              // as visually centered under the filter previews above it.
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, VideoTrack? localTrack) {
    final isActive = _activeFilterId == id;
    final tint = _tintFor(id);
    final size = isActive ? 66.0 : 58.0;

    // IgnorePointer: a native video view would otherwise take the tap
    // meant for this filter chip (tap "did nothing").
    Widget preview = (localTrack != null && !_isCameraOff)
        ? IgnorePointer(
            child: VideoTrackRenderer(
              localTrack,
              fit: VideoViewFit.cover,
              mirrorMode: _isFrontCamera
                  ? VideoViewMirrorMode.mirror
                  : VideoViewMirrorMode.off,
            ),
          )
        : Container(color: const Color(0xFF3A3A3A));

    // The tint is a plain painted layer stacked ON TOP of the video, not a
    // ColorFilter applied to it — see the note above _filterLabels for why.
    // This is also exactly how the Figma reference builds each swatch: one
    // shared base image plus a translucent colour wash per filter.
    preview = Stack(
      fit: StackFit.expand,
      children: [
        preview,
        if (tint != null) IgnorePointer(child: Container(color: tint)),
        if (id == 'none')
          const Center(
            child: Icon(
              Icons.not_interested_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _activeFilterId = id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(isActive ? 3 : 0),
                child: ClipOval(child: SizedBox.expand(child: preview)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCategoryTab({
    required Widget icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? Colors.white : Colors.white38;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme.merge(
              data: IconThemeData(color: color, size: 20),
              child: icon,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceEndLive() async {
    final token = _storeHelper.getAccessToken();
    try {
      if (widget.isHost) {
        await _serviceHelper.postHelper(
          target: '/v1/live/end',
          token: token,
          data: {"rem": "yes"},
        );
      } else {
        await _serviceHelper.postHelper(
          target: '/v1/live/${widget.liveId}/leave',
          token: token,
          data: {"hi": "ok"},
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error in force end/leave: $e");
    }
  }

  Future<void> _cleanupLive() async {
    if (_isCleanedUp) return;
    _isCleanedUp = true;

    // 1. API call first (server broadcasts live_ended while socket is still up)
    final token = _storeHelper.getAccessToken();
    try {
      if (widget.isHost) {
        await _serviceHelper.postHelper(
          target: '/v1/live/end',
          token: token,
          data: {"rem": "yes"},
        );
      } else {
        await _serviceHelper.postHelper(
          target: '/v1/live/${widget.liveId}/leave',
          token: token,
          data: {"hi": "ok"},
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error in cleanup API: $e");
    }

    // 2. Leave socket room
    _socket.emit('leave_live_chat', {'liveStreamId': widget.liveId});
    _socket.off('new_comment');
    _socket.off('live_ended');
    _socket.off('viewer_joined');
    _socket.off('viewer_left');
    _socket.off('live_gift_received');
    _socket.off('live_goal_updated');
    _socket.off('live_goal_achieved');
    _socket.off('live_premium_updated');
    _socket.off('live_premium_joined');
    _socketReconnectSub?.cancel();
    _goalAchievedTimer?.cancel();

    // 3. Disconnect LiveKit
    try {
      _listener?.dispose();
      await _room?.disconnect();
      await _room?.dispose();
    } catch (e) {
      if (kDebugMode) print("Error disconnecting LiveKit: $e");
    }

    // 4. Dispose controllers
    _chatController.dispose();
    _chatScrollController.dispose();
  }

  String _formatLiveDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _confirmExit() async {
    final shouldExit = widget.isHost
        ? await _showEndStreamSheet()
        : await _showLeaveSheet();

    if (shouldExit == true) {
      Get.back();
    }
  }

  // Matches the "End Stream?" bottom sheet: real diamonds earned this
  // session + real elapsed duration, a primary purple End Stream button,
  // and a Continue button to dismiss and keep broadcasting.
  Future<bool?> _showEndStreamSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'End Stream?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _endStreamStat(
                    icon: Icons.diamond_outlined,
                    iconColor: const Color(0xFF7ED6FF),
                    value: WalletHelper.format(_sessionDiamonds),
                  ),
                  _endStreamStat(
                    icon: Icons.access_time_rounded,
                    iconColor: Colors.white70,
                    value: _formatLiveDuration(
                      DateTime.now().difference(_liveStartedAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B3EE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'End Stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _endStreamStat({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Simpler leave confirmation for viewers — same visual language, but no
  // earnings/duration since a viewer doesn't have any.
  Future<bool?> _showLeaveSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Leave Live Stream?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B3EE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Leave',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionController>(
      builder: (_) => _buildSessionScope(context),
    );
  }

  Widget _buildSessionScope(BuildContext context) {
    if (_streamEnded) {
      // Broadcast is over — no live UI left to protect with an exit
      // confirm sheet, so allow normal back navigation.
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: StreamEndedOverlay(
            hostId: widget.hostId,
            hostName: widget.hostName,
            hostImage: widget.hostImage,
            currentLiveId: widget.liveId,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. LIVE VIDEO BACKGROUND
            _buildVideoBackground(),

            // Gradient overlay for chat readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // 2. UI overlay
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildRankingBar(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GiftBannerQueue(
                      key: _giftBannerQueueKey,
                      currentUserId:
                          context
                              .watch<SessionController>()
                              .session
                              ?.user
                              ?.id ??
                          '',
                      onComboTap: _onComboResend,
                    ),
                  ),
                  const Spacer(),
                  if (_isChatVisible)
                    SizedBox(
                      height: 250,
                      // reverse: true + indexing from the end of the list
                      // makes messages hug the bottom of the box and grow
                      // upward as new ones arrive, like a normal chat UI —
                      // instead of stacking from the top with empty space
                      // left underneath when there are only a few messages.
                      child: ListView.builder(
                        controller: _chatScrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _liveChats.length,
                        itemBuilder: (context, index) {
                          final chat =
                              _liveChats[_liveChats.length - 1 - index];
                          return _buildChatRow(
                            name: chat['name'],
                            message: chat['message'],
                            badge: chat['badge'],
                            isJoinMessage: chat['isJoin'],
                            isSelfStart: chat['isSelfStart'] == true,
                            image: chat['image'],
                            vip: chat['vip'],
                            isVerifyied: chat['is_verified'],
                          );
                        },
                      ),
                    ),
                  _buildBottomInputBar(),
                  if (widget.isHost && _isFilterPanelOpen)
                    _buildFilterPanel()
                  else
                    _buildLiveToolbar(),
                ],
              ),
            ),

            // 3. Gift SVGA + audio overlay — topmost layer, above the top
            // bar/chat/toolbar too (was below the UI overlay before, which
            // is why it never actually appeared over everything). Wrapped
            // in IgnorePointer internally, so it never blocks taps on the
            // UI underneath despite being on top.
            LiveGiftOverlay(key: _giftOverlayKey),

            // 4. "Goal Achieved!" celebration (everyone in the room).
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: (_showGoalAchieved && _goal != null)
                        ? GoalAchievedBanner(
                            key: const ValueKey('goal-achieved'),
                            targetAmount: _goal!.targetAmount,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The host's own local camera video track, if any — shared by the main
  /// full-screen preview and the small live-preview thumbnails in the
  /// filter panel so they're never out of sync with each other.
  VideoTrack? _localCameraTrack() {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return null;
    for (var pub in localParticipant.videoTrackPublications) {
      if (pub.track != null && pub.track is VideoTrack) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  // ==========================================
  // VIDEO BACKGROUND — shows LiveKit video fullscreen
  // ==========================================
  Widget _buildVideoBackground() {
    // --- Connecting state ---
    if (_isConnecting) {
      return Container(
        color: const Color(0xFF121212),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B3EE8)),
        ),
      );
    }

    // --- Error state ---
    if (_connectionError != null) {
      return Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _connectionError!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (widget.isHost)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _forceEndLive();
                    Get.back();
                  },
                  icon: const Icon(Icons.stop_circle, color: Colors.white),
                  label: const Text("Force End Live"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B3EE8),
                  ),
                  child: const Text("Go Back"),
                ),
            ],
          ),
        ),
      );
    }

    // --- HOST: show local camera feed ---
    if (widget.isHost) {
      final localTrack = _localCameraTrack();

      if (localTrack == null || _isCameraOff) {
        return _buildVideoPlaceholder();
      }

      // Only the FRONT camera should show mirrored (selfie-style) — this
      // was hardcoded to always mirror, so switching to the back camera
      // kept flipping it left/right too, which looks wrong for anything
      // with readable text/directionality in frame (and isn't how a rear
      // camera should ever look).
      final renderer = VideoTrackRenderer(
        localTrack,
        fit: VideoViewFit.cover,
        mirrorMode: _isFrontCamera
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.off,
      );

      // Painted overlay, not a ColorFilter on the video — see the note
      // above _filterLabels. This guarantees the tint is actually visible
      // on the live preview regardless of how the platform renders the
      // camera texture underneath.
      final tint = _tintFor(_activeFilterId);
      return tint == null
          ? renderer
          : Stack(
              fit: StackFit.expand,
              children: [
                renderer,
                IgnorePointer(child: Container(color: tint)),
              ],
            );
    }

    // --- VIEWER: show broadcaster's remote video ---
    if (_hostVideoTrack != null) {
      return VideoTrackRenderer(_hostVideoTrack!, fit: VideoViewFit.cover);
    }

    // Waiting for host to publish video
    return _buildVideoPlaceholder(
      message: "Waiting for host video stream...",
      showSpinner: true,
    );
  }

  Widget _buildVideoPlaceholder({String? message, bool showSpinner = false}) {
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner)
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: Color(0xFF8B3EE8)),
              )
            else
              Icon(
                _isCameraOff ? Icons.videocam_off : Icons.person,
                color: Colors.white30,
                size: 64,
              ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR (Host info, viewers, close)
  // ==========================================
  // ==========================================
  // LIVE GOAL — bound to this live session on the server
  // ==========================================
  double get _goalProgress => _goal?.progress ?? 0;

  Future<void> _loadGoal() async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/${widget.liveId}/goal',
      token: _storeHelper.getAccessToken(),
    );
    if (response is! Success || !mounted) return;
    try {
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (body is Map && body['success'] == true) {
        setState(() => _goal = LiveGoal.fromJson(body['data']));
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing live goal: $e');
    }
  }

  // ==========================================
  // PREMIUM — entry gift for this live session
  // ==========================================
  Future<void> _loadPremium() async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/${widget.liveId}/premium',
      token: _storeHelper.getAccessToken(),
    );
    if (response is! Success || !mounted) return;
    try {
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final info = LivePremiumInfo.fromJson(body is Map ? body['data'] : null);
      if (info == null) return;
      setState(() => _premium = info);
      if (!widget.isHost && info.isPremium && !info.hasAccess) {
        _goToPremiumGate(info);
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing premium info: $e');
    }
  }

  /// Viewer without access: leave the room and show "Join now".
  void _goToPremiumGate(LivePremiumInfo info) {
    if (_leavingForPremiumGate) return;
    _leavingForPremiumGate = true;
    ToastHelper.showInfoToast(message: 'This live is now Premium');
    openPremiumGateIfRequired(
      {
        'requiresPremium': true,
        'premium': {
          'isPremium': true,
          'hasAccess': false,
          if (info.entryGift != null)
            'entryGift': {
              'id': info.entryGift!.id,
              'name': info.entryGift!.name,
              'image': info.entryGift!.imageUrl,
              'svga': info.entryGift!.svga,
              'music': info.entryGift!.sound,
              'price': info.entryGift!.price,
              'duration': info.entryGift!.durationSeconds,
            },
        },
      },
      liveId: widget.liveId,
      hostId: widget.hostId,
      hostName: widget.hostName,
      hostImage: widget.hostImage,
      streamTitle: widget.streamTitle,
      replace: true,
    );
  }

  /// Host: Premium button. Off → pick entry gift → Premium on.
  /// On → change the gift or turn Premium off.
  Future<void> _openLivePremium() async {
    if (!widget.isHost) return;
    final token = _storeHelper.getAccessToken();

    if (_premium.isPremium) {
      final action = await showPremiumManageSheet(
        context,
        entryGift: _premium.entryGift,
      );
      if (!mounted || action == null) return;
      if (action == PremiumManageAction.turnOff) {
        final response = await _serviceHelper.deleteHelper(
          target: '/v1/live/${widget.liveId}/premium',
          token: token,
        );
        if (!mounted) return;
        if (response is Success) {
          setState(() => _premium = LivePremiumInfo.off);
          ToastHelper.showSuccessToast(message: 'Premium is off');
        } else if (response is Failure) {
          ToastHelper.showErrorToast(
            message: response.errorResponse.toString(),
          );
        }
        return;
      }
    }

    final gift = await showEntryGiftSheet(
      context,
      selectedGiftId: _premium.entryGift?.id,
    );
    if (gift == null || !mounted) return;

    final response = await _serviceHelper.postHelper(
      target: '/v1/live/${widget.liveId}/premium',
      token: token,
      data: {'giftId': gift.id},
    );
    if (!mounted) return;
    if (response is Success) {
      setState(
        () => _premium = LivePremiumInfo(isPremium: true, entryGift: gift),
      );
      ToastHelper.showSuccessToast(message: 'Your live is now Premium');
      _loadPremium();
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
  }

  void _celebrateGoal() {
    _goalAchievedTimer?.cancel();
    setState(() => _showGoalAchieved = true);
    _goalAchievedTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showGoalAchieved = false);
    });
  }

  /// Host only: set a goal (none yet) or view / cancel the current one.
  Future<void> _manageGoal() async {
    if (!widget.isHost) return;
    final goal = _goal;
    final token = _storeHelper.getAccessToken();

    if (goal == null) {
      final amount = await showSetGoalDialog(context);
      if (amount == null || !mounted) return;
      final response = await _serviceHelper.postHelper(
        target: '/v1/live/${widget.liveId}/goal',
        token: token,
        data: {'amount': amount},
      );
      if (!mounted) return;
      if (response is Success) {
        try {
          final body = response.data is String
              ? jsonDecode(response.data as String)
              : response.data;
          setState(() => _goal = LiveGoal.fromJson(body['data']));
        } catch (_) {
          _loadGoal();
        }
      } else if (response is Failure) {
        ToastHelper.showErrorToast(message: response.errorResponse.toString());
        _loadGoal();
      }
      return;
    }

    final cancel = await showCurrentGoalDialog(
      context,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      isCompleted: goal.isCompleted,
    );
    if (cancel != true || !mounted) return;
    final response = await _serviceHelper.deleteHelper(
      target: '/v1/live/${widget.liveId}/goal',
      token: token,
    );
    if (!mounted) return;
    if (response is Success) {
      setState(() => _goal = null);
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
      _loadGoal();
    }
  }

  static String _compactCoins(num value) {
    String trim(double v) =>
        v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    if (value >= 1000000) return '${trim(value / 1000000)}M';
    if (value >= 1000) return '${trim(value / 1000)}K';
    return value.toInt().toString();
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: widget.isHost
                    ? _buildHostBadgesRow()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: _buildHostInfoCard()),
                          const SizedBox(width: 8),
                          _buildRecentAvatarsRow(),
                        ],
                      ),
              ),
              const SizedBox(width: 8),

              // LIVE indicator — a small dot + bold text, no pill
              // background (the reference design draws it directly over the
              // video, not inside a colored container). Dot uses the app's
              // button purple (0xFF8B3EE8, same as the rest of this
              // screen's buttons) instead of red per client feedback.
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B3EE8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_premium.isPremium) ...[
                const SizedBox(width: 6),
                const PremiumBadge(fontSize: 9),
              ],

              // Status icons (host only), shown only while that state is on:
              //  - red mic: muted from the toolbar's Mute button
              //  - red call-off: "Call off" is on (not receiving calls)
              // Tapping one turns that state back off.
              if (widget.isHost && _isMicMuted) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: _toggleMic,
                  child: SvgPicture.asset(
                    AssetsManager.liveMuteActive,
                    width: 21,
                    height: 21,
                  ),
                ),
              ],
              if (widget.isHost && _callsOff) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: _toggleCallsOff,
                  child: _toolbarIconWidget(
                    AssetsManager.liveCallOffActive,
                    size: 21,
                  ),
                ),
              ],

              const SizedBox(width: 10),
              // Close button — opens the End Stream / Leave confirmation sheet.
              InkWell(
                onTap: _confirmExit,
                child: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
            ],
          ),

          if (widget.isHost) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  WalletHelper.format(_sessionDiamonds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            //    _buildGiftProgressPill(),
          ],
        ],
      ),
    );
  }

  // Host's own view: the viewer-count badge (tap opens the viewer list) and
  // a fire badge. Per client feedback the fire badge is decoration only —
  // no tap action.
  Widget _buildHostBadgesRow() {
    return Row(
      children: [
        _buildCircleBadge(
          onTap: _openTopViewers,
          child: Text(
            '$_viewerCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () {
            showRankingSheet(
              context,
              liveId: widget.liveId,
              hostId: widget.hostId,
              isHost: widget.isHost,
            );
          },
          child: _buildCircleBadge(
            child: const Text('🔥', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleBadge({required Widget child, VoidCallback? onTap}) {
    final badge = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: child,
    );
    return onTap == null
        ? badge
        : InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: badge,
          );
  }

  // Gift-value-this-session progress pill: filled portion (against the
  // 9999 reference goal) + the current value as a plain number — no
  // avatar, no "/9999" suffix, per client feedback simplifying the
  // original Figma-matched version. Reuses _sessionDiamonds, the same
  // number shown just above it, since this pill tracks gift value
  // received during the stream, not wallet balance.
  Widget _buildGiftProgressPill() {
    final progress = _goalProgress;
    return SizedBox(
      width: 40,
      height: 24,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF7247EF),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              WalletHelper.format(_sessionDiamonds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Viewer's own view: who am I watching, how many others are watching,
  // and a follow button — real info a viewer actually needs.
  Widget _buildHostInfoCard() {
    // Real follow state, shared with the mini profile sheet via the same
    // globally-registered TargetProfileProvider instance.
    final profileProvider = context.watch<TargetProfileProvider>();
    final hasHostProfile =
        profileProvider.targetId == widget.hostId &&
        profileProvider.profile != null;
    final isFollowingHost = hasHostProfile
        ? profileProvider.profile!.isFollowing
        : false;

    void openHostMiniProfile() {
      if (widget.hostId.isEmpty) return;
      showMiniProfileSheet(
        context,
        userId: widget.hostId,
        userName: widget.hostName,
        userImage: widget.hostImage,
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: openHostMiniProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AvatarHelper.resolve(widget.hostImage),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: openHostMiniProfile,
                child: Text(
                  widget.hostName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: _openTopViewers,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_viewerCount",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (!isFollowingHost)
            GestureDetector(
              onTap: widget.hostId.isEmpty
                  ? null
                  : () => context.read<TargetProfileProvider>().followUser(
                      userId: widget.hostId,
                    ),
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3A54),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "+ Follow",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Viewer-only: small overlapping avatar stack + total-gifters count next
  // to the host info card. Gifters always show first (most recent gift
  // first, with a small badge showing how many gifts that person has sent
  // this session) — recent joiners only fill in when nobody's gifted yet.
  // The trailing number is the count of distinct people who've sent a gift
  // this session, not the visible-avatar count.
  Widget _buildRecentAvatarsRow() {
    final visible = [..._gifterAvatars, ..._joinerAvatars].take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    const avatarSize = 22.0;
    const overlapStep = 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: avatarSize + (visible.length - 1) * overlapStep,
          height: avatarSize + 6,
          child: Stack(
            children: [
              for (var i = 0; i < visible.length; i++)
                Positioned(
                  left: i * overlapStep,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: AvatarHelper.resolve(
                            visible[i].image,
                          ),
                        ),
                      ),
                      if (visible[i].giftCount > 0)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B3EE8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${visible[i].giftCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${_allGifterIds.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Ranking Bar
  // ==========================================
  // Gift-value-this-session progress bar: transparent-black track, purple
  // fill that grows with _sessionDiamonds (bumped live by the
  // 'live_gift_received' socket handler), "current/9999" label. Was a
  // flat wallet-balance pill before — now an actual progress indicator per
  // client feedback.
  // Goal-aware progress bar under the top bar:
  //  - no goal:   coin + this session's gift total (host: tap to set a goal)
  //  - active:    purple fill, "current/target"
  //  - completed: full green fill, "✓ target"
  // Host taps it to set / view / cancel the goal.
  Widget _buildGoalBar(double progress) {
    final goal = _goal;
    final completed = goal?.isCompleted ?? false;
    final fillColor = completed
        ? const Color(0xFF22B573)
        : const Color(0xFF7247EF);

    Widget label;
    if (goal == null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/icons/sm-coin.png", width: 12),
          const SizedBox(width: 3),
          Text(
            WalletHelper.format(_sessionDiamonds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.isHost) ...[
            const SizedBox(width: 6),
            const GoalIcon(color: Colors.white70, size: 12),
          ],
        ],
      );
    } else {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          completed
              ? const Icon(Icons.check_circle, color: Colors.white, size: 12)
              : const GoalIcon(color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            completed
                ? 'Goal ${_compactCoins(goal.targetAmount)}'
                : '${_compactCoins(goal.currentAmount)}/${_compactCoins(goal.targetAmount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final bar = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 90),
      child: SizedBox(
        height: 22,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: goal == null ? 0 : progress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    color: fillColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: label,
              ),
            ],
          ),
        ),
      ),
    );

    return widget.isHost
        ? GestureDetector(onTap: _manageGoal, child: bar)
        : bar;
  }

  Widget _buildRankingBar() {
    final progress = _goalProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Daily Ranking pill — viewer-only (this was commented out, per
          // your note; restoring it but gated so it doesn't show on the
          // host's own broadcast screen).
          if (!widget.isHost) ...[
            InkWell(
              onTap: () {
                showRankingSheet(
                  context,
                  liveId: widget.liveId,
                  hostId: widget.hostId,
                  isHost: widget.isHost,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("🔥", style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      "Daily Ranking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          _buildGoalBar(progress),
        ],
      ),
    );
  }

  // ==========================================
  // Chat Row
  // ==========================================
  Widget _buildChatRow({
    required String name,
    required String message,
    String? badge,
    required bool isJoinMessage,
    bool isSelfStart = false,
    String? image,
    int? vip,
    bool? isVerifyied,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or wave icon for join messages
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[100],
            backgroundImage: AvatarHelper.resolve(image),
          ),

          const SizedBox(width: 8),

          Expanded(
            // "You started a live stream" is one inline line ("You" in
            // gray, the rest in white) instead of the usual stacked
            // name-line + message-line — matches how the host's own
            // stream-start notice reads in the reference design.
            child: isSelfStart
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: ' $message',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isJoinMessage
                                  ? Colors.white70
                                  : const Color(0xFF90CAF9),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            badge == "VIP"
                                ? SvgPicture.asset(AssetsManager.vip)
                                : SvgPicture.asset(AssetsManager.svip),
                          ],
                        ],
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          color: isJoinMessage ? Colors.white70 : Colors.white,
                          fontSize: 15,
                          fontWeight: isJoinMessage
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bottom Input Bar
  // ==========================================
  Widget _buildChatInputField() {
    final field = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AssetsManager.liveChat,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type...",
                hintStyle: TextStyle(
                  height: 1.8,
                  color: Colors.white.withOpacity(0.6),
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendComment(),
            ),
          ),
        ],
      ),
    );

    return widget.isHost
        ? SizedBox(width: context.width * 0.70, child: field)
        : Expanded(child: field);
  }

  Widget _buildBottomInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Host mic/camera toggles now live in the labeled toolbar below
          // (_buildLiveToolbar) as Mute/Switch — kept out of this row so it
          // stays a single, uncluttered "type a message" bar.

          // Chat input. Host has no trailing icons anymore (share/gift/send
          // are viewer-only), so it goes back to the fixed 70%-of-screen
          // width you originally set. Viewer keeps it Expanded so it still
          // yields space correctly to the 3 icons that follow it.
          _buildChatInputField(),
          if (!widget.isHost) const SizedBox(width: 8),

          // Share, gift, and camera/send icons — viewers only. Host's own
          // broadcast screen keeps just the input bar (mic/camera controls
          // already live in the labeled toolbar below).
          if (!widget.isHost) ...[
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.reply_all_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 28,
              ),
            ),
            const SizedBox(width: 8),

            // Gift icon — opens the gift sheet, and on selection emits it.
            GestureDetector(
              onTap: () async {
                final gift = await showGiftBottomSheet(context);
                if (gift != null) {
                  await _sendGift(gift);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(AssetsManager.giftSm, width: 30, height: 30),
              ),
            ),
            const SizedBox(width: 8),

            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.send,
                  color: Colors.deepPurpleAccent,
                  size: 20,
                ),
                onPressed: _sendComment,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // Live Toolbar — Switch/Mute/Premium/Chat/Start 1:1/Call off/Filter
  // ==========================================
  Widget _buildLiveToolbar() {
    final items = [
      _ToolbarItemData(
        iconAsset: AssetsManager.liveSwitchCamera,
        label: 'Switch',
        onTap: _switchCamera,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.liveMute,
        activeIconAsset: AssetsManager.liveMuteActive,
        label: 'Mute',
        onTap: _toggleMic,
        active: _isMicMuted,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.livePremium,
        label: 'Premium',
        onTap: _openLivePremium,
        active: _premium.isPremium,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.liveChat,
        label: 'Chat',
        onTap: _openPrivateMessages,
        badgeCount: Get.find<SessionController>().session?.unReadMessages ?? 0,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.liveStart1on1,
        label: 'Start 1:1',
        onTap: _openStart1on1,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.liveCallOff,
        activeIconAsset: AssetsManager.liveCallOffActive,
        label: 'Call off',
        onTap: _toggleCallsOff,
        active: _callsOff,
      ),
      _ToolbarItemData(
        iconAsset: AssetsManager.liveFilter,
        label: 'Filter',
        onTap: () => setState(() => _isFilterPanelOpen = true),
        active: _activeFilterId != 'none',
      ),
    ];

    return !widget.isHost
        ? SizedBox()
        : Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items.map(_buildToolbarItem).toList(),
            ),
          );
  }

  Widget _buildToolbarItem(_ToolbarItemData data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _toolbarIconWidget(
                  (data.active && data.activeIconAsset != null)
                      ? data.activeIconAsset!
                      : data.iconAsset,
                  size: 22,
                ),
                if (data.badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3A54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${data.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // Renders a toolbar icon asset, dispatching on file type: SVGs go through
  // flutter_svg as usual, PNGs (currently just the call-off icons, which
  // had to be converted — see the AssetsManager comment) go through
  // Image.asset. The white call-off PNG has no "off" slash baked in (the
  // original SVG drew it as a separate vector line), so that one specific
  // case draws it back on top in code instead of shipping a dead icon.
  Widget _toolbarIconWidget(String assetPath, {required double size}) {
    if (assetPath == AssetsManager.liveCallOff) {
      return _buildCallOffIcon(size: size);
    }
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(assetPath, width: size, height: size);
    }
    return Image.asset(assetPath, width: size, height: size);
  }

  Widget _buildCallOffIcon({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Image.asset(AssetsManager.liveCallOff, width: size, height: size),
          CustomPaint(
            size: Size(size, size),
            painter: const _DiagonalSlashPainter(),
          ),
        ],
      ),
    );
  }
}

/// Small hand-drawn "lipstick" glyph for the filter-panel "Makeup" category
/// tab. No exported asset was provided for Beauty/Makeup (only Filter's
/// three-circle icon was), so this stays a code-drawn approximation until
/// a real asset is supplied.
class _LipstickIcon extends StatelessWidget {
  const _LipstickIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    final size = IconTheme.of(context).size ?? 20;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LipstickPainter(color)),
    );
  }
}

class _LipstickPainter extends CustomPainter {
  final Color color;
  _LipstickPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cap — the cylindrical base of the lipstick tube.
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.55,
        size.width * 0.44,
        size.height * 0.4,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(cap, strokePaint);

    // Product — the angled bullet tip above the cap.
    final tip = Path()
      ..moveTo(size.width * 0.30, size.height * 0.56)
      ..lineTo(size.width * 0.38, size.height * 0.10)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.0,
        size.width * 0.62,
        size.height * 0.10,
      )
      ..lineTo(size.width * 0.70, size.height * 0.56)
      ..close();
    canvas.drawPath(tip, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LipstickPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Reproduces the diagonal "off" slash the original call_off.svg drew as a
/// separate vector <path> (M20,7 L7.72,22.79 in a 28x28 viewBox) over its
/// pattern-filled handset image — needed because that image now renders via
/// Image.asset instead of SvgPicture (see AssetsManager.liveCallOff).
class _DiagonalSlashPainter extends CustomPainter {
  const _DiagonalSlashPainter();

  static const double _viewBox = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _viewBox;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(20 * k, 7 * k),
      Offset(7.72119 * k, 22.787 * k),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalSlashPainter oldDelegate) => false;
}

/// One person shown in the top bar's small recent-activity avatar row —
/// either a gifter (giftCount > 0, badge shown) or a recent joiner
/// (giftCount stays 0, no badge). See _gifterAvatars/_joinerAvatars.
class _AvatarActivity {
  final String userId;
  final String? image;
  int giftCount;

  _AvatarActivity({required this.userId, this.image, this.giftCount = 0});
}

/// One icon+label entry in the live room's bottom toolbar. Icons are the
/// exact SVGs exported from the Figma live-streaming screen (see
/// AssetsManager's "live room toolbar" section) — colors are baked into
/// each file, so no runtime tinting is applied on top of them.
/// [activeIconAsset], when set, is swapped in while [active] is true (e.g.
/// the red "muted" mic in place of the white default one); items without a
/// distinct active asset just keep showing [iconAsset] regardless of state.
class _ToolbarItemData {
  final String iconAsset;
  final String? activeIconAsset;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int badgeCount;

  const _ToolbarItemData({
    required this.iconAsset,
    this.activeIconAsset,
    required this.label,
    required this.onTap,
    this.active = false,
    this.badgeCount = 0,
  });
}
