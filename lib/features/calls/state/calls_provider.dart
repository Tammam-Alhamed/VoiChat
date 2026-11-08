import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/ringtone_service.dart';
import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/network/socket_service.dart';
import '../data/call_repository.dart';
import '../presentation/in_call_screen.dart';
import '../presentation/incoming_call_scree.dart';
import '../presentation/outgoing_call_screen.dart';
import '../widgets/tate_call_bottom_sheet.dart';

/// The LiveKit SFU server URL.
const String _kLiveKitUrl = 'wss://sfu-st.voichat.live';

/// Call states that drive the UI.
enum CallState {
  idle,
  outgoing, // Caller is waiting for the receiver to pick up.
  incoming, // Receiver sees the incoming-call screen.
  connecting, // LiveKit room is being connected.
  connected, // Both parties are in the room.
  ended, // Call has ended / been declined / timed out.
}

// ─────────────────────────────────────────────────────────────────────────────
// Gift model — used by [GiftsDialog] / [showGiftsDialog].
//
// NOTE: the backend does NOT yet implement the socket events used here
// ('send_call_gift' / 'call_gift_received'). You need to add a handler in
// `index.js` mirroring the existing `send_live_gift` handler, e.g.:
//
//   socket.on('send_call_gift', ({ callId, receiverId, gift }) => {
//     io.to(receiverId).emit('call_gift_received', {
//       callId, gift, senderId: userId, senderName: socket.user.name,
//     });
//   });
//
// Wallet deduction / validation for the gift cost should happen server-side
// (this client only emits the request).
// ─────────────────────────────────────────────────────────────────────────────
class GiftModel {
  final String id;
  final String name;
  final String emoji;
  final int coinCost;

  const GiftModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.coinCost,
  });
}

const List<GiftModel> kCallGifts = [
  GiftModel(id: 'rose', name: 'Rose', emoji: '🌹', coinCost: 10),
  GiftModel(id: 'heart', name: 'Heart', emoji: '❤️', coinCost: 20),
  GiftModel(id: 'kiss', name: 'Kiss', emoji: '💋', coinCost: 30),
  GiftModel(id: 'ring', name: 'Ring', emoji: '💍', coinCost: 100),
  GiftModel(id: 'car', name: 'Car', emoji: '🚗', coinCost: 250),
  GiftModel(id: 'crown', name: 'Crown', emoji: '👑', coinCost: 500),
];

/// Manages the entire call lifecycle:
///
///  idle → outgoing / incoming → connecting → connected → ended → idle
///
/// Features:
/// - Video calls by default (can be switched to audio-only by either party)
/// - Handles FCM push (foreground / background / terminated)
/// - Handles socket events (call_ended, call_cancelled, call_answered, incoming_call)
/// - Cancels notification + pops screen when caller cancels before answer
/// - Full LiveKit room management with camera + mic controls
/// - Rating bottom sheet shown to the CALLER only, and only if the call
///   actually connected (regardless of which side ended it)
/// - In-call gift sending
class CallsProvider extends ChangeNotifier {
  final CallRepository _repo;
  final SocketService _socketService;
  final RingtoneService _ringtone = RingtoneService();

  CallsProvider({
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
    required SocketService socketService,
  }) : _repo = CallRepository(
         serviceHelper: serviceHelper,
         storeHelper: storeHelper,
       ),
       _socketService = socketService {
    _listenForSocketCallEvents();
  }

  // ─── Observable state ─────────────────────────────────────────────────────

  CallState _state = CallState.idle;
  CallState get state => _state;

  String? _callId;
  String? get callId => _callId;

  String? _roomName;
  String? _token; // LiveKit token for the local participant.

  /// True if the local user initiated this call (caller), false if receiver.
  /// Used to decide who sees the rating bottom sheet when the call ends.
  bool _isCaller = false;
  bool get isCaller => _isCaller;

  /// The other party's user id — needed to target gift/socket events.
  String? _otherPartyId;
  String? get otherPartyId => _otherPartyId;

  String? _otherPartyName;
  String get otherPartyName => _otherPartyName ?? 'Unknown';

  String? _otherPartyImage;
  String? get otherPartyImage => _otherPartyImage;

  /// video = both see each other; audio = voice only.
  String _callType = 'video';
  String get callType => _callType;
  bool get isVideo => _callType == 'video';

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Elapsed call time in seconds (only while [state] == connected).
  int _elapsed = 0;
  int get elapsed => _elapsed;

  String get elapsedFormatted {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = true; // Default speaker on for video calls
  bool get isSpeakerOn => _isSpeakerOn;

  bool _isCameraOff = false;
  bool get isCameraOff => _isCameraOff;

  bool _isFrontCamera = true;
  bool get isFrontCamera => _isFrontCamera;

  // ─── Gifts ────────────────────────────────────────────────────────────────

  bool _isSendingGift = false;
  bool get isSendingGift => _isSendingGift;

  /// Last gift received from the other party — set briefly so the UI
  /// (e.g. InCallScreen) can play a gift animation, then cleared.
  GiftModel? _lastReceivedGift;
  GiftModel? get lastReceivedGift => _lastReceivedGift;

  // ─── Internal ─────────────────────────────────────────────────────────────

  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  Timer? _callTimer;
  Timer? _timeoutTimer;

  // Remote participant video track — exposed to InCallScreen
  VideoTrack? _remoteVideoTrack;
  VideoTrack? get remoteVideoTrack => _remoteVideoTrack;

  LocalVideoTrack? _localVideoTrack;
  LocalVideoTrack? get localVideoTrack => _localVideoTrack;

  // ─── Initiate an outgoing call ────────────────────────────────────────────

  /// Called when the current user taps "Call" on another user's profile.
  /// Default is video call — receiver can switch to audio-only.
  Future<void> initiateCall({
    required String receiverId,
    required String receiverName,
    String? receiverImage,
    String callType = 'video',
  }) async {
    if (_state != CallState.idle) return;

    _setState(CallState.outgoing);
    _isCaller = true;
    _otherPartyId = receiverId;
    _otherPartyName = receiverName;
    _otherPartyImage = receiverImage;
    _callType = callType;
    _isSpeakerOn = callType == 'video';
    _errorMessage = null;

    try {
      final result = await _repo.initiateCall(
        receiverId: receiverId,
        callType: callType,
      );

      if (result == null) {
        _handleError('Failed to initiate call');
        return;
      }

      _callId = result.call.id;
      _roomName = result.roomName;
      _token = result.callerToken;

      // Play dial tone for caller
      _ringtone.playDialTone();

      // Navigate to the outgoing call screen
      Get.to(
        () => OutgoingCallScreen(
          callId: _callId!,
          name: receiverName,
          avatarUrl: receiverImage,
          callType: callType,
        ),
      );

      // Auto-timeout after 45 seconds if no answer
      _timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_state == CallState.outgoing) {
          endCall();
        }
      });

      // Connect to LiveKit room immediately so video/audio is ready when receiver joins
      await _connectToRoom();
    } on CallApiException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // ─── Handle an incoming call (from push notification / socket) ────────────

  /// Called when the device receives a push notification of type "call"
  /// OR when a socket "incoming_call" event arrives.
  ///
  /// [data] must contain: callId, callType, roomName, callerId, callerName,
  /// callerImage.
  ///
  /// NOTE: `callerId` must be added to the backend's FCM data payload and
  /// the `incoming_call` socket payload — it's required so [_otherPartyId]
  /// can be used to target gift events back to the caller.
  void handleIncomingCall(Map<String, dynamic> data) {
    if (_state != CallState.idle) {
      if (kDebugMode) {
        print(
          'CallsProvider: ignoring incoming call, already in state $_state',
        );
      }
      return;
    }

    _isCaller = false;
    _callId = data['callId']?.toString();
    _callType = data['callType']?.toString() ?? 'video';
    _roomName = data['roomName']?.toString();
    _otherPartyId = data['callerId']?.toString();
    _otherPartyName = data['callerName']?.toString();
    _otherPartyImage = data['callerImage']?.toString();
    _isSpeakerOn = _callType == 'video';
    _errorMessage = null;

    _setState(CallState.incoming);

    // Play ringtone
    _ringtone.playRingtone();

    // Navigate to the incoming call screen
    Get.to(
      () => IncomingCallScreen(
        callId: _callId ?? '',
        name: _otherPartyName ?? 'Unknown',
        avatarUrl: _otherPartyImage,
        callType: _callType,
      ),
    );

    // Auto-timeout after 30 seconds if receiver doesn't answer.
    // NOTE: we only reset state here — IncomingCallScreen's own Consumer
    // watches `state == idle` and pops itself. We deliberately do NOT also
    // call navigation here to avoid a double-pop race.
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_state == CallState.incoming) {
        _ringtone.stop();
        _reset();
      }
    });
  }

  // ─── Answer an incoming call ──────────────────────────────────────────────

  /// Called when the receiver taps the green "Accept" button.
  Future<void> answerCall() async {
    if (_state != CallState.incoming || _callId == null) return;

    _timeoutTimer?.cancel();
    _ringtone.stop();
    _setState(CallState.connecting);

    try {
      final result = await _repo.answerCall(_callId!);

      if (result == null) {
        _handleError('Failed to answer call');
        return;
      }

      _token = result.token;
      _roomName = result.roomName;

      // Connect to LiveKit room
      await _connectToRoom();

      _setState(CallState.connected);
      _startCallTimer();

      // Navigate to the in-call screen (replace the incoming screen)
      Get.off(
        () => InCallScreen(
          callId: _callId!,
          otherPartyName: otherPartyName,
          otherPartyImage: _otherPartyImage,
          callType: _callType,
        ),
      );
    } on CallApiException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // ─── Decline an incoming call ─────────────────────────────────────────────

  /// Called when the receiver taps the red "Reject" button.
  Future<void> declineCall() async {
    if (_callId == null) return;

    _timeoutTimer?.cancel();
    _ringtone.stop();

    try {
      await _repo.declineCall(_callId!);
    } catch (e) {
      if (kDebugMode) print('CallsProvider.declineCall error: $e');
    }

    _reset();
    _safeNavigateBack();
  }

  // ─── End an active or outgoing call ───────────────────────────────────────

  /// Called when either party taps the end-call button.
  Future<void> endCall() async {
    if (_callId == null) return;

    final callIdToEnd = _callId!;
    final hadConnected = _state == CallState.connected;

    _timeoutTimer?.cancel();
    _ringtone.stop();
    _stopCallTimer();

    try {
      await _repo.endCall(callIdToEnd);
    } catch (e) {
      if (kDebugMode) print('CallsProvider.endCall error: $e');
    }

    await _disconnectRoom();
    _setState(CallState.ended);

    _safeNavigateBack();
    _maybeShowRatingSheet(callIdToEnd, hadConnected: hadConnected);

    Future.delayed(const Duration(milliseconds: 300), _reset);
  }

  // ─── Rating ───────────────────────────────────────────────────────────────

  Future<void> rateCall(String callId, int rating, String comment) async {
    await _repo.rateCall(callId: callId, rating: rating, comment: comment);
  }

  /// Shows the rating bottom sheet to the CALLER only, and only if the call
  /// actually reached `connected` at some point — regardless of which side
  /// ended the call. Fixes the bug where the sheet either never appeared
  /// (caller ends the call) or appeared for the wrong party (receiver ends
  /// the call, which the backend rejects with "Only the caller can rate").
  void _maybeShowRatingSheet(String callId, {required bool hadConnected}) {
    if (!_isCaller || !hadConnected) return;

    Future.delayed(const Duration(milliseconds: 400), () {
      Get.bottomSheet(
        RateCallBottomSheet(callId: callId),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    });
  }

  // ─── Switch between video and audio ───────────────────────────────────────

  /// Toggles between video and audio-only mode.
  /// When switching to audio: disables camera on both sides via socket.
  /// When switching to video: re-enables camera.
  Future<void> toggleVideoMode() async {
    if (_state != CallState.connected) return;

    if (isVideo) {
      // Switch to audio-only
      _callType = 'audio';
      _isCameraOff = true;
      try {
        await _room?.localParticipant?.setCameraEnabled(false);
        _localVideoTrack = null;
      } catch (e) {
        if (kDebugMode)
          print('CallsProvider.toggleVideoMode camera off error: $e');
      }
    } else {
      // Switch back to video
      _callType = 'video';
      _isCameraOff = false;
      try {
        await _room?.localParticipant?.setCameraEnabled(true);
        // Re-capture local video track
        _localVideoTrack =
            _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
      } catch (e) {
        if (kDebugMode)
          print('CallsProvider.toggleVideoMode camera on error: $e');
      }
    }
    notifyListeners();
  }

  // ─── Audio controls ───────────────────────────────────────────────────────

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!_isMuted);
    } catch (e) {
      if (kDebugMode) print('CallsProvider.toggleMute error: $e');
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await _room?.setSpeakerOn(_isSpeakerOn);
    } catch (e) {
      if (kDebugMode) print('CallsProvider.toggleSpeaker error: $e');
    }
    notifyListeners();
  }

  /// Flip between front and rear cameras (video calls only). Uses LiveKit's
  /// own `setCameraPosition` (asks the platform for "the front camera" /
  /// "the back camera" directly) instead of guessing which of
  /// `Hardware.instance.enumerateDevices()`'s entries is which by index —
  /// that guess breaks on phones that enumerate more than 2 cameras (most
  /// modern phones report 3+ back cameras before the front one), silently
  /// selecting the wrong physical camera while `_isFrontCamera` still got
  /// toggled as if the switch worked.
  Future<void> switchCamera() async {
    if (!isVideo || _isCameraOff) return;

    try {
      final publication =
          _room?.localParticipant?.videoTrackPublications.isNotEmpty == true
          ? _room!.localParticipant!.videoTrackPublications.first
          : null;

      if (publication?.track is LocalVideoTrack) {
        final track = publication!.track as LocalVideoTrack;

        final targetPosition = _isFrontCamera
            ? CameraPosition.back
            : CameraPosition.front;
        await track.setCameraPosition(targetPosition);

        // Read the camera position back from the track instead of assuming
        // the switch landed on what we asked for.
        final options = track.currentOptions;
        _isFrontCamera = options is CameraCaptureOptions
            ? options.cameraPosition == CameraPosition.front
            : targetPosition == CameraPosition.front;
      }
    } catch (e) {
      if (kDebugMode) {
        print('switchCamera error: $e');
      }
    }

    notifyListeners();
  }

  // ─── Gifts ────────────────────────────────────────────────────────────────

  /// Sends [gift] to the other party in the current call.
  /// Returns true if the request was emitted successfully.
  ///
  /// Requires a backend socket handler for 'send_call_gift' (see the note
  /// above [GiftModel]). Wallet balance validation happens server-side.
  Future<bool> sendGift(GiftModel gift) async {
    if (_callId == null || _otherPartyId == null || _isSendingGift) {
      return false;
    }

    _isSendingGift = true;
    notifyListeners();

    try {
      _socketService.emit('send_call_gift', {
        'callId': _callId,
        'receiverId': _otherPartyId,
        'gift': {
          'id': gift.id,
          'name': gift.name,
          'emoji': gift.emoji,
          'coinCost': gift.coinCost,
        },
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('CallsProvider.sendGift error: $e');
      return false;
    } finally {
      _isSendingGift = false;
      notifyListeners();
    }
  }

  void _clearReceivedGift() {
    _lastReceivedGift = null;
    notifyListeners();
  }

  // ─── LiveKit room management ──────────────────────────────────────────────

  Future<void> _connectToRoom() async {
    if (_token == null || _token!.isEmpty) return;

    try {
      _room = Room();
      _roomListener = _room!.createListener();

      _roomListener!
        ..on<RoomDisconnectedEvent>((event) {
          if (kDebugMode) print('CallsProvider: Room disconnected');
          if (_state == CallState.connected || _state == CallState.connecting) {
            endCall();
          }
        })
        ..on<ParticipantConnectedEvent>((event) {
          if (kDebugMode) {
            print(
              'CallsProvider: Participant connected: ${event.participant.identity}',
            );
          }
          // Caller side: receiver just joined → transition to connected
          if (_state == CallState.outgoing) {
            _ringtone.stop();
            _setState(CallState.connected);
            _startCallTimer();

            Get.off(
              () => InCallScreen(
                callId: _callId!,
                otherPartyName: otherPartyName,
                otherPartyImage: _otherPartyImage,
                callType: _callType,
              ),
            );
          }
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          if (kDebugMode) {
            print(
              'CallsProvider: Participant disconnected: ${event.participant.identity}',
            );
          }
          if (_state == CallState.connected) {
            endCall();
          }
        })
        ..on<TrackSubscribedEvent>((event) {
          // Capture remote video track when subscribed
          if (event.track is RemoteVideoTrack) {
            _remoteVideoTrack = event.track as VideoTrack;
            notifyListeners();
          }
        })
        ..on<TrackUnsubscribedEvent>((event) {
          if (event.track is RemoteVideoTrack) {
            _remoteVideoTrack = null;
            notifyListeners();
          }
        })
        ..on<TrackPublishedEvent>((event) {
          if (kDebugMode) print('CallsProvider: Track published');
        });

      // Room options — enable video for video calls
      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: const AudioPublishOptions(dtx: true),
        defaultVideoPublishOptions: isVideo
            ? const VideoPublishOptions(simulcast: true)
            : const VideoPublishOptions(),
      );

      await _room!.connect(_kLiveKitUrl, _token!, roomOptions: roomOptions);

      // Enable microphone always
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // Enable camera for video calls
      if (isVideo) {
        await _room!.localParticipant?.setCameraEnabled(true);
        _localVideoTrack =
            _room?.localParticipant?.videoTrackPublications.first.track;
      }

      // Set speaker on for video, earpiece for audio
      await _room!.setSpeakerOn(_isSpeakerOn);

      if (kDebugMode) {
        print(
          'CallsProvider: Connected to LiveKit room $_roomName (type: $_callType)',
        );
      }
    } catch (e) {
      if (kDebugMode) print('CallsProvider: LiveKit connect error: $e');
      _handleError('Failed to connect to call room');
    }
  }

  Future<void> _disconnectRoom() async {
    try {
      _roomListener?.dispose();
      _roomListener = null;
      _localVideoTrack = null;
      _remoteVideoTrack = null;
      await _room?.disconnect();
      await _room?.dispose();
      _room = null;
    } catch (e) {
      if (kDebugMode) print('CallsProvider: disconnect error: $e');
    }
  }

  // ─── Socket events ────────────────────────────────────────────────────────

  void _listenForSocketCallEvents() {
    // ── Call ended by the other party (while in call) ──────────────────────
    _socketService.on('call_ended', (data) {
      if (data is Map<String, dynamic>) {
        final eventCallId = data['callId']?.toString();
        if (eventCallId == _callId &&
            _state != CallState.idle &&
            _state != CallState.ended) {
          final hadConnected = _state == CallState.connected;

          _ringtone.stop();
          _stopCallTimer();
          _disconnectRoom();
          _setState(CallState.ended);
          _safeNavigateBack();

          _maybeShowRatingSheet(eventCallId!, hadConnected: hadConnected);

          Future.delayed(const Duration(milliseconds: 300), _reset);
        }
      }
    });

    // ── Caller cancelled BEFORE receiver answered ──────────────────────────
    // Dismisses the incoming-call screen + stops the ringtone. We only call
    // _reset() here — IncomingCallScreen's own Consumer watches for
    // `state == idle` and pops itself, avoiding a double-pop race.
    _socketService.on('call_cancelled', (data) {
      if (data is Map<String, dynamic>) {
        final eventCallId = data['callId']?.toString();
        if (eventCallId == _callId && _state == CallState.incoming) {
          if (kDebugMode) print('CallsProvider: call cancelled by caller');
          _timeoutTimer?.cancel();
          _ringtone.stop();

          final callerName = _otherPartyName ?? 'The caller';
          _reset();

          ToastHelper.showInfoToast(
            message: '$callerName cancelled the call',
          );
        }
      }
    });

    // ── Call answered by receiver (caller side) ────────────────────────────
    _socketService.on('call_answered', (data) {
      if (data is Map<String, dynamic>) {
        final eventCallId = data['callId']?.toString();
        if (eventCallId == _callId && _state == CallState.outgoing) {
          _ringtone.stop();
          _timeoutTimer?.cancel();
          // LiveKit ParticipantConnectedEvent handles the full transition
        }
      }
    });

    // ── Incoming call via socket (fast path when app is foregrounded) ──────
    _socketService.on('incoming_call', (data) {
      if (data is Map<String, dynamic>) {
        handleIncomingCall(data);
      }
    });

    // ── Gift received from the other party ─────────────────────────────────
    _socketService.on('call_gift_received', (data) {
      if (data is Map<String, dynamic>) {
        final eventCallId = data['callId']?.toString();
        if (eventCallId != _callId) return;

        final giftData = data['gift'];
        if (giftData is Map) {
          _lastReceivedGift = GiftModel(
            id: giftData['id']?.toString() ?? '',
            name: giftData['name']?.toString() ?? '',
            emoji: giftData['emoji']?.toString() ?? '🎁',
            coinCost: giftData['coinCost'] is int
                ? giftData['coinCost']
                : int.tryParse(giftData['coinCost']?.toString() ?? '0') ?? 0,
          );
          notifyListeners();
          Future.delayed(const Duration(seconds: 3), _clearReceivedGift);
        }
      }
    });
  }

  // ─── Call timer ───────────────────────────────────────────────────────────

  void _startCallTimer() {
    _elapsed = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      notifyListeners();
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setState(CallState newState) {
    _state = newState;
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _ringtone.stop();
    _timeoutTimer?.cancel();
    _stopCallTimer();
    _setState(CallState.ended);

    if (kDebugMode) print('CallsProvider error: $message');

    ToastHelper.showErrorToast(message: message);

    _safeNavigateBack();
    Future.delayed(const Duration(milliseconds: 300), _reset);
  }

  /// Safe back navigation — only pops if there's something to pop.
  void _safeNavigateBack() {
    try {
      if (Get.currentRoute != '/') {
        Get.back();
      }
    } catch (_) {}
  }

  void _reset() {
    _state = CallState.idle;
    _callId = null;
    _roomName = null;
    _token = null;
    _isCaller = false;
    _otherPartyId = null;
    _otherPartyName = null;
    _otherPartyImage = null;
    _callType = 'video';
    _errorMessage = null;
    _elapsed = 0;
    _isMuted = false;
    _isSpeakerOn = true;
    _isCameraOff = false;
    _isFrontCamera = true;
    _remoteVideoTrack = null;
    _localVideoTrack = null;
    _isSendingGift = false;
    _lastReceivedGift = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _callTimer?.cancel();
    _timeoutTimer?.cancel();
    _ringtone.dispose();
    _disconnectRoom();
    _socketService.off('call_ended');
    _socketService.off('call_cancelled');
    _socketService.off('call_answered');
    _socketService.off('incoming_call');
    _socketService.off('call_gift_received');
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gift picker — call [showGiftsDialog] from InCallScreen (e.g. a gift-icon
// button) to open it.
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the gift picker as a bottom sheet. Call from InCallScreen:
///
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.card_giftcard, color: Colors.white),
///   onPressed: () => showGiftsDialog(context),
/// )
/// ```
void showGiftsDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GiftsDialog(),
  );
}

class GiftsDialog extends StatefulWidget {
  const GiftsDialog({super.key});

  @override
  State<GiftsDialog> createState() => _GiftsDialogState();
}

class _GiftsDialogState extends State<GiftsDialog> {
  String? _sendingGiftId;

  Future<void> _onGiftTap(GiftModel gift) async {
    if (_sendingGiftId != null) return;

    setState(() => _sendingGiftId = gift.id);

    final provider = context.read<CallsProvider>();
    final ok = await provider.sendGift(gift);

    if (!mounted) return;
    setState(() => _sendingGiftId = null);

    if (ok) {
      Navigator.of(context).pop();
    } else {
      ToastHelper.showErrorToast(message: 'Failed to send gift');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send a gift',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kCallGifts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final gift = kCallGifts[index];
              final isSending = _sendingGiftId == gift.id;

              return GestureDetector(
                onTap: () => _onGiftTap(gift),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSending)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(gift.emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 8),
                      Text(
                        gift.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${gift.coinCost}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
