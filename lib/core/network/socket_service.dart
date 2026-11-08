import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants.dart';
import '../helpers/store_helper.dart';

/// Manages the Socket.IO connection lifecycle.
///
/// The server (src/sockets/index.js) authenticates via
/// `socket.handshake.auth.token` and emits:
///   - `user_typing`        → { userId, conversationId }
///   - `user_stop_typing`   → { userId, conversationId }
///   - `user_status`        → { userId, status: 'online'|'offline' }
///   - `new_message`        → full message object (if wired from REST controller)
///   - `message_read_receipt` → { messageId, conversationId, readBy, readAt }
///   - `conversation_accepted` → { conversationId, acceptedBy }
///   - `conversation_request_removed` → { conversationId, removedBy }
class SocketService {
  final StoreHelper _storeHelper;

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  bool _hasConnectedBefore = false;

  final _reconnectedController = StreamController<void>.broadcast();

  /// Fires each time the socket connects again after having been connected.
  Stream<void> get reconnectedStream => _reconnectedController.stream;

  SocketService({required StoreHelper storeHelper})
    : _storeHelper = storeHelper;

  // ─── Connection lifecycle ──────────────────────────────────────────────────

  void connect() {
    if (_isConnected || _socket != null) return;

    final token = _storeHelper.getAccessToken();

    // Known socket_io_client v2 issues with HTTPS URLs:
    //  1. Omitting the port causes it to resolve as :0 (default port lookup bug).
    //     Fix: always include explicit port 443 for HTTPS.
    //  2. setPath() adds a trailing # to the URL in some builds.
    //     Fix: omit setPath() — socket.io server uses /socket.io by default.
    //  3. transport=['websocket'] skips the EIO handshake → HTTP 400.
    //     Fix: start with polling so the server issues a session ID,
    //     then the client upgrades to WebSocket automatically.
    _socket = io.io(
      Constants.socketServer,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      final isReconnect = _hasConnectedBefore;
      _hasConnectedBefore = true;
      _isConnected = true;
      _registerInternalListeners();
      // Server-side room memberships (e.g. a live room) are lost when the
      // connection drops; screens listen to this to re-join and re-sync.
      if (isReconnect) _reconnectedController.add(null);
      if (kDebugMode) print('SocketService: connected ✓');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      if (kDebugMode) print('SocketService: disconnected');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) print('SocketService: connect error: $err');
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _hasConnectedBefore = false;
  }

  // ─── Event emitters ────────────────────────────────────────────────────────

  void emitTyping(String receiverId, String conversationId) {
    _socket?.emit('typing', {
      'receiverId': receiverId,
      'conversationId': conversationId,
    });
  }

  void emitStopTyping(String receiverId, String conversationId) {
    _socket?.emit('stop_typing', {
      'receiverId': receiverId,
      'conversationId': conversationId,
    });
  }

  void emitMessageRead(
    String messageId,
    String conversationId,
    String senderId,
  ) {
    _socket?.emit('message_read', {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
    });
  }

  final _newMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get newMessageStream =>
      _newMessageController.stream;

  final _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageDeletedStream =>
      _messageDeletedController.stream;

  // A message request was accepted (by tapping Accept or by replying).
  final _conversationAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationAcceptedStream =>
      _conversationAcceptedController.stream;

  // A message request was declined by the receiver or cancelled by the sender.
  final _requestRemovedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get requestRemovedStream =>
      _requestRemovedController.stream;

  // ─── Event listeners ───────────────────────────────────────────────────────

  void _registerInternalListeners() {
    _socket?.off('conversation_accepted');
    _socket?.on('conversation_accepted', (data) {
      if (data is Map) {
        _conversationAcceptedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.off('conversation_request_removed');
    _socket?.on('conversation_request_removed', (data) {
      if (data is Map) {
        _requestRemovedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.off('new_message');
    _socket?.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        _newMessageController.add(data);
      }
    });

    _socket?.off('message_deleted');
    _socket?.on('message_deleted', (data) {
      if (data is Map<String, dynamic>) {
        _messageDeletedController.add(data);
      }
    });
  }

  void onTyping(void Function(String userId, String conversationId) callback) {
    _socket?.off('user_typing');
    _socket?.on('user_typing', (data) {
      if (data is Map) {
        callback(
          data['userId']?.toString() ?? '',
          data['conversationId']?.toString() ?? '',
        );
      }
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, void Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void onStopTyping(
    void Function(String userId, String conversationId) callback,
  ) {
    _socket?.off('user_stop_typing');
    _socket?.on('user_stop_typing', (data) {
      if (data is Map) {
        callback(
          data['userId']?.toString() ?? '',
          data['conversationId']?.toString() ?? '',
        );
      }
    });
  }

  void onUserStatus(void Function(String userId, String status) callback) {
    _socket?.off('user_status');
    _socket?.on('user_status', (data) {
      if (data is Map) {
        callback(
          data['userId']?.toString() ?? '',
          data['status']?.toString() ?? 'offline',
        );
      }
    });
  }

  void onMessageRead(void Function(Map<String, dynamic>) callback) {
    _socket?.off('message_read_receipt');
    _socket?.on('message_read_receipt', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offAll() {
    _socket?.off('new_message');
    _socket?.off('user_typing');
    _socket?.off('user_stop_typing');
    _socket?.off('user_status');
    _socket?.off('message_read_receipt');
  }
}
