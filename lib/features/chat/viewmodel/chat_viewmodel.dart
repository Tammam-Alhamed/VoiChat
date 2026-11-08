import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

import '../../home/tabs/messages/models/conversation_model.dart';
import '../../home/tabs/messages/viewmodel/messages_tab_viewmodel.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/helpers/store_helper.dart';
import '../../../core/utils/api_status.dart';

/// Progress for a video that's currently being prepared/sent: 'compressing'
/// while VideoCompress is working locally, then 'uploading' once the
/// compressed file is actually going out over the network.
class MediaUploadProgress {
  final String phase;
  final double value; // 0.0-1.0
  const MediaUploadProgress(this.phase, this.value);
}

class ChatViewModel extends ChangeNotifier {
  final SocketService _socketService;
  final ServiceHelper _serviceHelper;
  final StoreHelper _storeHelper;

  // Optional link to the messages list so we can keep its unread badge in
  // sync while this chat is open (see attachMessagesTab / setActiveConversation).
  MessagesTabViewModel? _messagesTabViewModel;

  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageDeletedSub;
  StreamSubscription? _requestAcceptedSub;
  StreamSubscription? _requestRemovedSub;

  /// Set by ChatScreen to surface send errors (e.g. the message-request
  /// limit) as a toast.
  void Function(String message)? onError;

  ChatViewModel({
    required SocketService socketService,
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
  }) : _socketService = socketService,
       _serviceHelper = serviceHelper,
       _storeHelper = storeHelper;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _conversationId;
  String? get conversationId => _conversationId;

  String? _receiverId;

  // ─── Message request state ────────────────────────────────────────────────
  // A new conversation starts as a 'pending' request (see backend
  // chat.service). Null until known (no conversation yet, or still loading).
  String? _conversationStatus;
  String? _requestedBy;

  // True once the lookup for an existing conversation has finished.
  bool _conversationResolved = false;

  /// The other person asked to message me and I haven't accepted yet.
  bool get isIncomingRequest =>
      _conversationStatus == ConversationStatus.pending &&
      _requestedBy == _receiverId;

  /// I sent a request and they haven't accepted it yet.
  bool get isOutgoingRequest =>
      _conversationStatus == ConversationStatus.pending &&
      _requestedBy != _receiverId;

  /// No conversation exists yet: the first message will be a request.
  bool get isNewChat => _conversationResolved && _conversationId == null;

  void _applyRequestState(dynamic status, dynamic requestedBy) {
    if (status != null) _conversationStatus = status.toString();
    if (requestedBy != null) _requestedBy = requestedBy.toString();
  }

  void _reportError(ApiStatus response) {
    if (response is Failure && response.errorResponse != null) {
      onError?.call(response.errorResponse.toString());
    }
  }

  /// Applies the conversation info returned by POST /chat/messages.
  void _applySendResult(Map<String, dynamic> result) {
    _conversationId = result['conversationId']?.toString();
    _conversationResolved = true;
    _applyRequestState(result['conversationStatus'], result['requestedBy']);
    _markConversationActive();

    final convId = _conversationId;
    if (convId == null) return;
    if (result['becameAccepted'] == true) {
      // My reply just accepted their request.
      _messagesTabViewModel?.markRequestAccepted(convId);
    } else if (result['isNewRequest'] == true) {
      // The sender's pending chat shows in their normal chat list.
      _messagesTabViewModel?.fetchConversations();
    }
  }

  // Block relationship with the other participant, as resolved server-side:
  // 'none' | 'blockedByMe' (I blocked them) | 'blockedMe' (they blocked me).
  // Drives whether the message box / call button are shown in ChatScreen.
  String _blockStatus = 'none';
  String get blockStatus => _blockStatus;
  bool get isBlocked => _blockStatus != 'none';

  // Live (or frozen/defaulted, per blockStatus) name & photo for the other
  // participant, refreshed on every fetchMessages() call. Null until the
  // first fetch resolves — ChatScreen falls back to its constructor params
  // until then.
  String? _otherUserName;
  String? get otherUserName => _otherUserName;
  String? _otherUserImage;
  String? get otherUserImage => _otherUserImage;

  // Keyed by the temp message id; only populated while a video message is
  // being compressed/uploaded (see sendVideoMessage).
  final Map<String, MediaUploadProgress> _mediaProgress = {};
  MediaUploadProgress? progressFor(String messageId) =>
      _mediaProgress[messageId];

  /// Call once after construction (e.g. from ChatScreen.initState) so this
  /// view model can tell the messages tab which conversation is currently
  /// open, keeping unread badges accurate.
  void attachMessagesTab(MessagesTabViewModel messagesTabViewModel) {
    _messagesTabViewModel = messagesTabViewModel;
    _messagesTabViewModel!.setActiveConversation(_conversationId);
  }

  void _markConversationActive() {
    _messagesTabViewModel?.setActiveConversation(_conversationId);
  }

  void initChat(
    String receiverId,
    String? conversationId, {
    String? status,
    String? requestedBy,
  }) {
    _receiverId = receiverId;
    _conversationId = conversationId;
    _conversationStatus = status;
    _requestedBy = requestedBy;
    _conversationResolved = conversationId != null;
    _messages.clear();
    _markConversationActive();

    _requestAcceptedSub?.cancel();
    _requestAcceptedSub = _socketService.conversationAcceptedStream.listen((
      data,
    ) {
      if (data['conversationId']?.toString() != _conversationId) return;
      _conversationStatus = ConversationStatus.accepted;
      notifyListeners();
    });

    _requestRemovedSub?.cancel();
    _requestRemovedSub = _socketService.requestRemovedStream.listen((data) {
      if (data['conversationId']?.toString() != _conversationId) return;
      // The request was declined/cancelled: the conversation no longer exists.
      _conversationId = null;
      _conversationStatus = null;
      _requestedBy = null;
      _messages.clear();
      _markConversationActive();
      notifyListeners();
    });

    _newMessageSub?.cancel();
    _newMessageSub = _socketService.newMessageStream.listen((data) {
      if (data['sender_id']?.toString() == _receiverId ||
          data['receiver_id']?.toString() == _receiverId) {
        final id = data['id']?.toString() ?? '';
        if (_messages.any((m) => m.id == id)) return;

        // A request can arrive while this chat is open with no conversation
        // yet — pick up its id and request state from the event.
        final eventConvId = data['conversation_id']?.toString();
        if (_conversationId == null && eventConvId != null) {
          _conversationId = eventConvId;
          _conversationResolved = true;
          _markConversationActive();
        }
        _applyRequestState(data['conversation_status'], data['requested_by']);

        final newMsg = MessageModel.fromJson(data);
        _messages.insert(0, newMsg);
        notifyListeners();

        // We're actively viewing this chat, so this incoming message is
        // effectively read immediately: tell the messages tab to keep the
        // badge at 0, and tell the server so the sender's ticks turn blue.
        // Not for an unanswered request: no "seen" until it's accepted.
        final convId = eventConvId ?? _conversationId;
        if (convId != null && !isIncomingRequest) {
          _messagesTabViewModel?.clearUnread(convId);
          _socketService.emitMessageRead(id, convId, newMsg.senderId);
        }
      }
    });

    _messageDeletedSub?.cancel();
    _messageDeletedSub = _socketService.messageDeletedStream.listen((data) {
      if (data['conversation_id']?.toString() == _conversationId ||
          _conversationId == null) {
        final id = data['message_id']?.toString() ?? '';
        _messages.removeWhere((m) => m.id == id);
        notifyListeners();
      }
    });

    // Update the "seen" tick color on our own outgoing messages in
    // real time when the other person reads them.
    _socketService.onMessageRead((data) {
      final id = data['messageId']?.toString();
      if (id == null) return;
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx != -1 && !_messages[idx].isRead) {
        _messages[idx].isRead = true;
        notifyListeners();
      }
    });

    if (_conversationId != null) {
      fetchMessages();
    } else {
      _resolveConversation();
    }
  }

  /// Opened from a profile (no conversation id locally): ask the server
  /// whether a conversation or request with this user already exists.
  Future<void> _resolveConversation() async {
    final receiverId = _receiverId;
    if (receiverId == null) return;

    final response = await _serviceHelper.getHelper(
      target: '/v1/chat/conversations/with/$receiverId',
      token: _storeHelper.getAccessToken(),
    );

    // The chat may have changed or found its conversation meanwhile.
    if (_receiverId != receiverId || _conversationId != null) return;

    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic> && data['id'] != null) {
          _conversationId = data['id'].toString();
          _applyRequestState(data['status'], data['requestedBy']);
          _markConversationActive();
          _conversationResolved = true;
          notifyListeners();
          fetchMessages();
          return;
        }
        _conversationResolved = true;
      } catch (e) {
        if (kDebugMode) print('ChatViewModel._resolveConversation error: $e');
      }
    }
    notifyListeners();
  }

  /// Accept the incoming request shown in this chat.
  Future<bool> acceptRequest() async {
    final convId = _conversationId;
    if (convId == null) return false;
    final response = await _serviceHelper.postHelper(
      target: '/v1/chat/requests/$convId/accept',
      token: _storeHelper.getAccessToken(),
      data: const {},
    );
    if (response is! Success) {
      _reportError(response);
      return false;
    }
    _conversationStatus = ConversationStatus.accepted;
    _messagesTabViewModel?.markRequestAccepted(convId);
    notifyListeners();
    // Now it's accepted: mark as read and send the "seen" receipts.
    fetchMessages();
    return true;
  }

  /// Block the person who sent this request, then delete the request.
  Future<bool> blockAndRemoveRequest() async {
    final otherId = _receiverId;
    if (otherId == null) return false;
    final response = await _serviceHelper.postHelper(
      target: '/v1/users/$otherId/block',
      token: _storeHelper.getAccessToken(),
      data: const {},
    );
    if (response is! Success) {
      _reportError(response);
      return false;
    }
    // Remove the request too (best-effort: the block already succeeded).
    final convId = _conversationId;
    if (convId != null) {
      await _serviceHelper.deleteHelper(
        target: '/v1/chat/requests/$convId',
        token: _storeHelper.getAccessToken(),
      );
      _messagesTabViewModel?.removeRequestLocally(convId);
    }
    return true;
  }

  /// Decline the incoming request (or cancel my own pending one).
  Future<bool> removeRequest() async {
    final convId = _conversationId;
    if (convId == null) return false;
    final response = await _serviceHelper.deleteHelper(
      target: '/v1/chat/requests/$convId',
      token: _storeHelper.getAccessToken(),
    );
    if (response is! Success) {
      _reportError(response);
      return false;
    }
    _messagesTabViewModel?.removeRequestLocally(convId);
    return true;
  }

  void setConversationIdAndFetch(String convId) {
    if (_conversationId == convId) return;
    _conversationId = convId;
    _markConversationActive();
    fetchMessages();
  }

  Future<void> fetchMessages({int page = 1, int limit = 30}) async {
    if (_conversationId == null || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target:
          '/v1/chat/conversations/$_conversationId/messages?page=$page&limit=$limit',
      token: token,
    );

    List<MessageModel> msgs = [];
    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final raw = body['data'];
          final list = raw is List ? raw : [];
          msgs = list
              .whereType<Map<String, dynamic>>()
              .map<MessageModel>((e) => MessageModel.fromJson(e))
              .toList();
        }

        // Server-resolved block state + the name/photo the viewer is
        // actually allowed to see (frozen snapshot / default avatar / live
        // data, depending on who blocked whom). Refreshed on every fetch so
        // blocking/unblocking mid-conversation updates the UI immediately.
        final conv = body['meta']?['conversation'] as Map<String, dynamic>?;
        if (conv != null) {
          _applyRequestState(conv['status'], conv['requestedBy']);
          _blockStatus = conv['blockStatus']?.toString() ?? 'none';
          final otherUser = conv['otherUser'] as Map<String, dynamic>?;
          if (otherUser != null) {
            _otherUserName = otherUser['name']?.toString();
            final image = otherUser['profile_image']?.toString();
            _otherUserImage = (image == null || image.isEmpty) ? null : image;
          }
        }
      } catch (e) {
        if (kDebugMode) print('ChatViewModel.fetchMessages error: $e');
      }
    }

    if (page == 1) {
      _messages = msgs;

      // The REST call above already marks these messages as read in the DB
      // (see chat.controller.getMessages -> markAsRead). Also notify the
      // sender in real time via socket so their checkmarks turn blue now,
      // not just next time they refresh.
      if (_conversationId != null && !isIncomingRequest) {
        for (final m in msgs) {
          if (m.senderId == _receiverId && !m.isRead) {
            _socketService.emitMessageRead(m.id, _conversationId!, m.senderId);
          }
        }
      }
    } else {
      _messages.addAll(msgs);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content, {MessageModel? replyTo}) async {
    if (_receiverId == null || content.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      content: content,
      messageType: 'text',
      createdAt: DateTime.now(),
      senderId: 'me',
      status: MessageStatus.sending,
      replyToId: replyTo?.id,
      replyToContent: replyTo?.content,
      replyToType: replyTo?.messageType,
      replyToSenderId: replyTo?.senderId,
    );

    _messages.insert(0, tempMsg);
    notifyListeners();

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.postHelper(
        target: '/v1/chat/messages',
        data: {
          'receiverId': _receiverId,
          'messageType': 'text',
          'content': content,
          if (replyTo != null) 'replyToMessageId': replyTo.id,
        },
        token: token,
      );

      if (response is Success) {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final result = body['data'] as Map<String, dynamic>;
          final index = _messages.indexWhere((m) => m.id == tempId);

          if (index != -1 && result['message'] != null) {
            final msgData = result['message'] as Map<String, dynamic>;
            final newMsg = MessageModel.fromJson(msgData);
            _messages[index] = newMsg;
            _applySendResult(result);
          }
        }
      } else {
        _reportError(response);
        throw Exception('Failed to send message');
      }
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = MessageModel(
          id: tempId,
          content: content,
          messageType: 'text',
          createdAt: _messages[index].createdAt,
          senderId: 'me',
          status: MessageStatus.failed,
          replyToId: replyTo?.id,
          replyToContent: replyTo?.content,
          replyToType: replyTo?.messageType,
          replyToSenderId: replyTo?.senderId,
        );
      }
    }
    notifyListeners();
  }

  Future<void> sendMediaMessage(String filePath, String messageType) async {
    if (_receiverId == null) return;

    _isLoading = true;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      content: null,
      messageType: messageType,
      mediaUrl: filePath,
      createdAt: DateTime.now(),
      senderId: 'me',
      status: MessageStatus.sending,
    );

    _messages.insert(0, tempMsg);
    notifyListeners();

    try {
      final token = _storeHelper.getAccessToken();
      final file = File(filePath);
      final multipartFile = await _serviceHelper.createMultipartFile(
        'media',
        file,
      );

      final response = await _serviceHelper.postMultipartHelper(
        target: '/v1/chat/messages',
        files: [multipartFile],
        fields: {'receiverId': _receiverId!, 'messageType': messageType},
        token: token,
      );

      if (response is Success) {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final result = body['data'] as Map<String, dynamic>;
          final index = _messages.indexWhere((m) => m.id == tempId);

          if (index != -1 && result['message'] != null) {
            final msgData = result['message'];
            final newMsg = MessageModel(
              id: msgData['id']?.toString() ?? '',
              content: msgData['content']?.toString(),
              messageType: msgData['message_type']?.toString() ?? 'text',
              mediaUrl: msgData['media_url']?.toString(),
              createdAt:
                  DateTime.tryParse(msgData['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              senderId: msgData['sender_id']?.toString() ?? '',
              status: MessageStatus.sent,
            );

            _messages[index] = newMsg;
            _applySendResult(result);
          }
        }
      } else {
        _reportError(response);
        throw Exception('Failed to send media message');
      }
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = MessageModel(
          id: tempId,
          content: null,
          messageType: messageType,
          mediaUrl: filePath,
          createdAt: _messages[index].createdAt,
          senderId: 'me',
          status: MessageStatus.failed,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  static const int _maxVideoDurationMs = 5 * 60 * 1000;

  /// Compresses [rawPath] in the background (with live progress), generates
  /// a thumbnail, then uploads both — also with live progress — before
  /// swapping the optimistic bubble for the server-confirmed message.
  Future<void> sendVideoMessage(String rawPath) async {
    if (_receiverId == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id: tempId,
      content: null,
      messageType: 'video',
      mediaUrl: rawPath,
      createdAt: DateTime.now(),
      senderId: 'me',
      status: MessageStatus.sending,
    );

    _messages.insert(0, tempMsg);
    _mediaProgress[tempId] = const MediaUploadProgress('compressing', 0.0);
    notifyListeners();

    Subscription? progressSub;
    try {
      // Camera recordings are capped by the OS picker's maxDuration, but a
      // video picked from the gallery isn't — enforce the 5-minute limit
      // here too before spending time compressing it.
      final info = await VideoCompress.getMediaInfo(rawPath);
      if ((info.duration ?? 0) > _maxVideoDurationMs) {
        throw Exception('Video is longer than 5 minutes');
      }

      progressSub = VideoCompress.compressProgress$.subscribe((progress) {
        _mediaProgress[tempId] = MediaUploadProgress(
          'compressing',
          (progress / 100).clamp(0.0, 1.0),
        );
        notifyListeners();
      });

      final compressed = await VideoCompress.compressVideo(
        rawPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      progressSub.unsubscribe();
      progressSub = null;

      final uploadPath = compressed?.path ?? rawPath;

      File? thumbFile;
      try {
        thumbFile = await VideoCompress.getFileThumbnail(rawPath, quality: 60);
      } catch (_) {
        thumbFile = null;
      }

      _mediaProgress[tempId] = const MediaUploadProgress('uploading', 0.0);
      notifyListeners();

      final token = _storeHelper.getAccessToken();
      final files = [
        await _serviceHelper.createMultipartFile('media', File(uploadPath)),
      ];
      if (thumbFile != null) {
        files.add(
          await _serviceHelper.createMultipartFile('thumbnail', thumbFile),
        );
      }

      final response = await _serviceHelper.postMultipartHelper(
        target: '/v1/chat/messages',
        files: files,
        fields: {'receiverId': _receiverId!, 'messageType': 'video'},
        token: token,
        onProgress: (p) {
          _mediaProgress[tempId] = MediaUploadProgress('uploading', p);
          notifyListeners();
        },
      );

      if (response is Success) {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final result = body['data'] as Map<String, dynamic>;
          final index = _messages.indexWhere((m) => m.id == tempId);

          if (index != -1 && result['message'] != null) {
            final msgData = result['message'];
            _messages[index] = MessageModel(
              id: msgData['id']?.toString() ?? '',
              content: msgData['content']?.toString(),
              messageType: msgData['message_type']?.toString() ?? 'video',
              mediaUrl: msgData['media_url']?.toString(),
              thumbnailUrl: msgData['thumbnail_url']?.toString(),
              createdAt:
                  DateTime.tryParse(msgData['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              senderId: msgData['sender_id']?.toString() ?? '',
              status: MessageStatus.sent,
            );
            _applySendResult(result);
          }
        }
      } else {
        _reportError(response);
        throw Exception('Failed to send video message');
      }
    } catch (e) {
      if (kDebugMode) print('sendVideoMessage error: $e');
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = MessageModel(
          id: tempId,
          content: null,
          messageType: 'video',
          mediaUrl: rawPath,
          createdAt: _messages[index].createdAt,
          senderId: 'me',
          status: MessageStatus.failed,
        );
      }
    } finally {
      progressSub?.unsubscribe();
      _mediaProgress.remove(tempId);
    }

    notifyListeners();
  }

  void sendTyping(bool isTyping) {
    if (_receiverId == null || _conversationId == null) return;
    if (isTyping) {
      _socketService.emitTyping(_receiverId!, _conversationId!);
    } else {
      _socketService.emitStopTyping(_receiverId!, _conversationId!);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.deleteHelper(
        target: '/v1/chat/messages/$messageId',
        token: token,
      );

      if (response is Failure) {
        throw Exception('Failed to delete message: ${response.errorResponse}');
      }

      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Failed to delete message: $e");
    }
  }

  /// Forwards [message] to [targetReceiverId]. Deliberately doesn't touch
  /// [_messages] — the target is usually a different conversation than the
  /// one currently open, so there's nothing local to update here. Reuses
  /// the already-hosted media_url/thumbnail_url instead of re-uploading for
  /// image/video/audio messages.
  Future<bool> forwardMessage(
    MessageModel message,
    String targetReceiverId,
  ) async {
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.postHelper(
        target: '/v1/chat/messages',
        data: {
          'receiverId': targetReceiverId,
          'messageType': message.messageType,
          'content': message.content,
          if (message.mediaUrl != null) 'mediaUrl': message.mediaUrl,
          if (message.thumbnailUrl != null)
            'thumbnailUrl': message.thumbnailUrl,
        },
        token: token,
      );
      return response is Success;
    } catch (e) {
      if (kDebugMode) print('Failed to forward message: $e');
      return false;
    }
  }

  /// Unblocks the other participant. On success both sides immediately go
  /// back to live data — no snapshot to restore, the next fetch just stops
  /// finding a Block row. ChatScreen calls fetchMessages() again after this
  /// returns true to pick up the reverted state.
  Future<bool> unblockUser() async {
    if (_receiverId == null) return false;
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.deleteHelper(
        target: '/v1/users/$_receiverId/unblock',
        token: token,
      );
      return response is Success;
    } catch (e) {
      if (kDebugMode) print('Failed to unblock user: $e');
      return false;
    }
  }

  /// "Delete chat" — removes the conversation from just this user's list;
  /// the other participant's history is untouched (see backend for why).
  Future<bool> deleteConversation() async {
    if (_conversationId == null) return false;
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.deleteHelper(
        target: '/v1/chat/conversations/$_conversationId',
        token: token,
      );
      return response is Success;
    } catch (e) {
      if (kDebugMode) print('Failed to delete conversation: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _messagesTabViewModel?.setActiveConversation(null);
    _newMessageSub?.cancel();
    _messageDeletedSub?.cancel();
    _requestAcceptedSub?.cancel();
    _requestRemovedSub?.cancel();
    onError = null;
    super.dispose();
  }
}
