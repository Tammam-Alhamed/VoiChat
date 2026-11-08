import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../../core/network/service_helper.dart';
import '../../../../../core/helpers/store_helper.dart';
import '../../../../../core/utils/api_status.dart';
import '../../../../../core/network/socket_service.dart';
import '../models/conversation_model.dart';
import '../../../../../core/domain/entities/client_user.dart';
import '../../../../../core/data/models/client_user_model.dart';

enum MessagesStatus { idle, loading, loaded, error }

class MessagesTabViewModel extends ChangeNotifier {
  final SocketService _socketService;
  final ServiceHelper _serviceHelper;
  final StoreHelper _storeHelper;

  MessagesTabViewModel({
    required SocketService socketService,
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
  }) : _socketService = socketService,
       _serviceHelper = serviceHelper,
       _storeHelper = storeHelper;

  // ─── State ────────────────────────────────────────────────────────────────────

  MessagesStatus _status = MessagesStatus.idle;
  MessagesStatus get status => _status;

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  int _totalUnread = 0;
  int get totalUnread => _totalUnread;

  bool get isLoading => _status == MessagesStatus.loading;

  // A refresh asked for while one was already running (e.g. a request got
  // accepted mid-fetch). Re-run once the current fetch finishes instead of
  // silently dropping it.
  bool _refreshQueued = false;

  // ─── Message requests ─────────────────────────────────────────────────────────
  // New conversations start as "requests" and only move into [conversations]
  // once the receiver replies or taps Accept (see backend chat.service).

  List<ConversationModel> _receivedRequests = [];
  List<ConversationModel> get receivedRequests => _receivedRequests;

  List<ConversationModel> _sentRequests = [];
  List<ConversationModel> get sentRequests => _sentRequests;

  /// Number of requests waiting for my answer (badge on the requests button).
  int _requestsCount = 0;
  int get requestsCount => _requestsCount;

  bool _requestsLoading = false;
  bool get requestsLoading => _requestsLoading;

  // Set of conversation IDs where the other user is currently typing
  final Set<String> _typingConversationIds = {};
  bool isTyping(String conversationId) =>
      _typingConversationIds.contains(conversationId);

  // The conversation currently open in ChatScreen (if any). While a
  // conversation is "active" we must not bump its unread badge when a
  // new_message socket event arrives for it, since the user is already
  // looking at it live. ChatViewModel calls setActiveConversation() when
  // it opens/loads a conversation and clears it (null) on dispose.
  String? _activeConversationId;
  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
    if (conversationId != null) {
      // In case a badge was already showing for it, clear it immediately.
      clearUnread(conversationId);
    }
  }

  // Suggested clients shown in the story row
  List<ClientUser> _suggestedClients = [];
  List<ClientUser> get suggestedClients => _suggestedClients;
  bool _suggestedLoading = false;
  bool get suggestedLoading => _suggestedLoading;

  // Socket stream subscriptions. Kept so init() can be called again without
  // stacking duplicate listeners (which would double-count unread badges).
  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageDeletedSub;
  StreamSubscription? _requestAcceptedSub;
  StreamSubscription? _requestRemovedSub;

  // ─── Init / dispose ───────────────────────────────────────────────────────────

  void init() {
    _socketService.connect();
    _registerSocketListeners();
    fetchConversations();
    fetchRequests();
    fetchSuggestedClients();
  }

  // ─── REST ──────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _decodeBody(dynamic response) {
    if (response is! Success) return null;
    try {
      return response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('MessagesTabViewModel decode error: $e');
      return null;
    }
  }

  /// Parses a paginated conversation list response. Returns null on failure
  /// so callers can keep the previous list instead of wiping it.
  ({List<ConversationModel> items, int total})? _parseConversationPage(
    dynamic response,
  ) {
    final body = _decodeBody(response);
    if (body == null || body['success'] != true) return null;
    final raw = body['data'];
    final list = (raw is List ? raw : const [])
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .toList();
    final total = (body['meta']?['total'] as num?)?.toInt() ?? list.length;
    return (items: list, total: total);
  }

  Future<void> fetchConversations({int page = 1, int limit = 30}) async {
    if (_status == MessagesStatus.loading) {
      _refreshQueued = true;
      return;
    }
    _status = MessagesStatus.loading;
    notifyListeners();

    final token = _storeHelper.getAccessToken();

    // Fetch conversations
    final convFuture = _serviceHelper.getHelper(
      target: '/v1/chat/conversations?page=$page&limit=$limit',
      token: token,
    );

    // Fetch unread count (also carries the pending-requests count)
    final unreadFuture = _serviceHelper.getHelper(
      target: '/v1/chat/unread-count',
      token: token,
    );

    final results = await Future.wait([convFuture, unreadFuture]);

    final parsed = _parseConversationPage(results[0]);
    if (parsed != null) {
      // Keep local-only pin state across refreshes.
      final pinned = _conversations
          .where((c) => c.isPinned)
          .map((c) => c.id)
          .toSet();
      _conversations = parsed.items;
      for (final c in _conversations) {
        c.isPinned = pinned.contains(c.id);
      }
      _sortPinnedFirst();
    }

    final unreadBody = _decodeBody(results[1]);
    if (unreadBody != null) {
      _totalUnread = (unreadBody['data']?['count'] as num?)?.toInt() ?? 0;
      final reqCount = unreadBody['data']?['requestsCount'] as num?;
      if (reqCount != null) _requestsCount = reqCount.toInt();
    }

    _status = MessagesStatus.loaded;
    notifyListeners();

    if (_refreshQueued) {
      _refreshQueued = false;
      fetchConversations(page: page, limit: limit);
    }
  }

  Future<void> refresh() => fetchConversations();

  /// Loads the message requests this user received. (Requests the user
  /// SENT stay in their normal chat list — see backend getConversations.)
  Future<void> fetchRequests() async {
    if (_requestsLoading) return;
    _requestsLoading = true;
    notifyListeners();

    final response = await _serviceHelper.getHelper(
      target: '/v1/chat/requests?type=received&limit=50',
      token: _storeHelper.getAccessToken(),
    );

    final received = _parseConversationPage(response);
    if (received != null) {
      _receivedRequests = received.items;
      _requestsCount = received.total;
    }

    _requestsLoading = false;
    notifyListeners();
  }

  /// "Delete All" on the requests screen.
  Future<bool> removeAllRequests() async {
    final response = await _serviceHelper.deleteHelper(
      target: '/v1/chat/requests',
      token: _storeHelper.getAccessToken(),
    );
    if (response is! Success) return false;
    _receivedRequests = [];
    _requestsCount = 0;
    notifyListeners();
    return true;
  }

  /// Accept a received request: it moves into the normal conversations list.
  Future<bool> acceptRequest(String conversationId) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/chat/requests/$conversationId/accept',
      token: _storeHelper.getAccessToken(),
      data: const {},
    );
    if (response is! Success) return false;
    markRequestAccepted(conversationId);
    return true;
  }

  /// Decline a received request, or cancel one I sent. Deletes it for both.
  Future<bool> removeRequest(String conversationId) async {
    final response = await _serviceHelper.deleteHelper(
      target: '/v1/chat/requests/$conversationId',
      token: _storeHelper.getAccessToken(),
    );
    if (response is! Success) return false;
    removeRequestLocally(conversationId);
    return true;
  }

  /// Local bookkeeping once a request became a normal conversation (via the
  /// API, a reply, or a socket event from the other side).
  void markRequestAccepted(String conversationId) {
    final wasReceived = _receivedRequests.any((c) => c.id == conversationId);
    _receivedRequests.removeWhere((c) => c.id == conversationId);
    _sentRequests.removeWhere((c) => c.id == conversationId);
    if (wasReceived) {
      _requestsCount = (_requestsCount - 1).clamp(0, 9999);
    }
    notifyListeners();
    fetchConversations();
  }

  void removeRequestLocally(String conversationId) {
    final wasReceived = _receivedRequests.any((c) => c.id == conversationId);
    _receivedRequests.removeWhere((c) => c.id == conversationId);
    _sentRequests.removeWhere((c) => c.id == conversationId);
    if (wasReceived) {
      _requestsCount = (_requestsCount - 1).clamp(0, 9999);
    }
    notifyListeners();
  }

  /// The conversation (normal or request) with [userId], if it's loaded.
  ConversationModel? conversationWith(String userId) {
    for (final list in [_conversations, _receivedRequests, _sentRequests]) {
      for (final c in list) {
        if (c.otherUser.id == userId) return c;
      }
    }
    return null;
  }

  Future<void> fetchSuggestedClients() async {
    if (_suggestedLoading) return;
    _suggestedLoading = true;
    notifyListeners();

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target: '/v1/users/clients?is_online=true&limit=15',
      token: token,
    );

    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true) {
          final raw = body['data'];
          final list = raw is List ? raw : [];
          _suggestedClients = list
              .whereType<Map<String, dynamic>>()
              .map(ClientUserModel.fromJson)
              .toList();
        }
      } catch (e) {
        if (kDebugMode)
          print('MessagesTabViewModel.fetchSuggestedClients error: $e');
      }
    }

    _suggestedLoading = false;
    notifyListeners();
  }

  // ─── Local conversation actions (pin / delete) ────────────────────────────────

  void _sortPinnedFirst() {
    _conversations.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });
  }

  void togglePin(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    _conversations[idx].isPinned = !_conversations[idx].isPinned;
    _sortPinnedFirst();
    notifyListeners();
  }

  void deleteConversations(Set<String> ids) {
    _conversations.removeWhere((c) => ids.contains(c.id));
    notifyListeners();

    // Persist the deletion server-side too (per-user — the other
    // participant's copy is untouched). Fire-and-forget: the local list is
    // already updated optimistically above, and ChatScreen's own delete
    // flow already awaits this same endpoint directly when it initiates
    // the deletion itself.
    final token = _storeHelper.getAccessToken();
    for (final id in ids) {
      _serviceHelper.deleteHelper(
        target: '/v1/chat/conversations/$id',
        token: token,
      );
    }
  }

  // ─── Socket listeners ─────────────────────────────────────────────────────────

  void _registerSocketListeners() {
    _newMessageSub?.cancel();
    _newMessageSub = _socketService.newMessageStream.listen(_handleNewMessage);

    _messageDeletedSub?.cancel();
    _messageDeletedSub = _socketService.messageDeletedStream.listen((data) {
      final conversationId = data['conversation_id']?.toString();
      final messageId = data['message_id']?.toString();
      if (conversationId != null && messageId != null) {
        final idx = _conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1 && _conversations[idx].lastMessage?.id == messageId) {
          fetchConversations();
        }
      }
    });

    _requestAcceptedSub?.cancel();
    _requestAcceptedSub = _socketService.conversationAcceptedStream.listen((
      data,
    ) {
      final id = data['conversationId']?.toString();
      if (id != null) markRequestAccepted(id);
    });

    _requestRemovedSub?.cancel();
    _requestRemovedSub = _socketService.requestRemovedStream.listen((data) {
      final id = data['conversationId']?.toString();
      if (id != null) removeRequestLocally(id);
    });

    _socketService.onTyping((userId, conversationId) {
      _typingConversationIds.add(conversationId);
      notifyListeners();
    });

    _socketService.onStopTyping((userId, conversationId) {
      _typingConversationIds.remove(conversationId);
      notifyListeners();
    });

    _socketService.onUserStatus((userId, status) {
      if (kDebugMode) print('User $userId is now $status');
    });
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    final conversationId =
        messageData['conversation_id']?.toString() ??
        messageData['conversationId']?.toString();
    if (conversationId == null) return;

    // A message on a pending conversation is a message request: it belongs
    // in the requests inbox, not the normal chat list.
    if (messageData['conversation_status']?.toString() ==
        ConversationStatus.pending) {
      _handleRequestMessage(conversationId, messageData);
      return;
    }

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) {
      fetchConversations();
      return;
    }

    final conv = _conversations[idx];

    final newMsg = MessageModel.fromJson(messageData);
    conv.lastMessage = newMsg;
    conv.updatedAt = newMsg.createdAt;

    // Don't inflate the badge for a conversation the user is currently
    // looking at in ChatScreen — they're already seeing the message live,
    // so it should stay "read" instead of building up unread count that
    // never clears when they navigate back.
    final isActive = conversationId == _activeConversationId;
    if (!isActive) {
      conv.unreadCount++;
      _totalUnread++;
    }

    final updated = _conversations.removeAt(idx);
    _conversations.insert(0, updated);

    notifyListeners();
  }

  void _handleRequestMessage(
    String conversationId,
    Map<String, dynamic> messageData,
  ) {
    final idx = _receivedRequests.indexWhere((c) => c.id == conversationId);
    if (idx == -1) {
      // First message of a brand-new request: bump the badge right away,
      // then load the full row (with the sender's profile) from the server.
      _requestsCount++;
      notifyListeners();
      fetchRequests();
      return;
    }

    final request = _receivedRequests[idx];
    final newMsg = MessageModel.fromJson(messageData);
    request.lastMessage = newMsg;
    request.updatedAt = newMsg.createdAt;
    if (conversationId != _activeConversationId) request.unreadCount++;

    _receivedRequests.removeAt(idx);
    _receivedRequests.insert(0, request);
    notifyListeners();
  }

  /// Forget the signed-in user's chats (logout). Socket listeners are
  /// re-registered by init() for the next account.
  void reset() {
    _newMessageSub?.cancel();
    _messageDeletedSub?.cancel();
    _requestAcceptedSub?.cancel();
    _requestRemovedSub?.cancel();
    _newMessageSub = null;
    _messageDeletedSub = null;
    _requestAcceptedSub = null;
    _requestRemovedSub = null;
    _status = MessagesStatus.idle;
    _conversations = [];
    _receivedRequests = [];
    _sentRequests = [];
    _requestsCount = 0;
    _requestsLoading = false;
    _totalUnread = 0;
    _refreshQueued = false;
    _typingConversationIds.clear();
    _activeConversationId = null;
    _suggestedClients = [];
    _suggestedLoading = false;
  }

  void clearUnread(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    final prev = _conversations[idx].unreadCount;
    if (prev > 0) {
      _conversations[idx].unreadCount = 0;
      _totalUnread = (_totalUnread - prev).clamp(0, 9999);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _newMessageSub?.cancel();
    _messageDeletedSub?.cancel();
    _requestAcceptedSub?.cancel();
    _requestRemovedSub?.cancel();
    super.dispose();
  }
}
