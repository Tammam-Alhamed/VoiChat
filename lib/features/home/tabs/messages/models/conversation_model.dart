/// Represents the other participant in a conversation.
class ConversationUserModel {
  final String id;
  final String name;
  final String profileImage;
  final bool isVerified;
  final bool isVip;

  const ConversationUserModel({
    required this.id,
    required this.name,
    required this.profileImage,
    this.isVerified = false,
    this.isVip = false,
  });

  factory ConversationUserModel.fromJson(Map<String, dynamic> json) {
    return ConversationUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profileImage: json['profile_image'],
      isVerified: json['is_verified'] == true,
      isVip: json['vip_member'] == true,
    );
  }
}

enum MessageStatus { sending, sent, failed }

/// Represents the last message preview or a single chat message.
class MessageModel {
  final String id;
  final String? content;
  final String messageType; // 'text' | 'image' | 'video' | 'audio'
  final String? mediaUrl;
  // Preview image for 'video' messages only (uploaded alongside the video).
  final String? thumbnailUrl;
  final DateTime createdAt;
  final String senderId;
  bool
  isRead; // mutable: updated in-place when a 'message_read_receipt' arrives
  final MessageStatus status;

  // Populated only when this message is a reply to another one (WhatsApp-
  // style quote). All null for a normal message.
  final String? replyToId;
  final String? replyToContent;
  final String? replyToType;
  final String? replyToSenderId;

  MessageModel({
    required this.id,
    this.content,
    this.messageType = 'text',
    this.mediaUrl,
    this.thumbnailUrl,
    required this.createdAt,
    required this.senderId,
    this.isRead = false,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.replyToContent,
    this.replyToType,
    this.replyToSenderId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final reply = json['repliedMessage'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString(),
      messageType: json['message_type']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      senderId: json['sender_id']?.toString() ?? '',
      isRead: json['is_read'] == true,
      status: MessageStatus.sent,
      replyToId: reply?['id']?.toString(),
      replyToContent: reply?['content']?.toString(),
      replyToType: reply?['message_type']?.toString(),
      replyToSenderId: reply?['sender_id']?.toString(),
    );
  }
}

/// Server-side conversation status values (see backend Conversation.status).
class ConversationStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
}

/// Represents a single conversation row in the messages tab (or in the
/// message requests screen, when [status] is 'pending').
class ConversationModel {
  final String id;
  final ConversationUserModel otherUser;
  MessageModel? lastMessage;
  int unreadCount;
  DateTime? updatedAt;
  bool isPinned;
  bool isTyping;

  /// 'pending' (a message request) or 'accepted' (a normal conversation).
  String status;

  /// The user who sent the first message / the request.
  final String? requestedBy;

  /// Someone asked to message me and I haven't accepted yet.
  bool isIncomingRequest;

  /// I asked to message them and they haven't accepted yet.
  bool isOutgoingRequest;

  ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.isPinned = false,
    this.isTyping = false,
    this.status = ConversationStatus.accepted,
    this.requestedBy,
    this.isIncomingRequest = false,
    this.isOutgoingRequest = false,
  });

  bool get isPending => status == ConversationStatus.pending;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['otherUser'] as Map<String, dynamic>? ?? {};
    final rawMsg = json['lastMessage'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      otherUser: ConversationUserModel.fromJson(rawUser),
      lastMessage: rawMsg != null ? MessageModel.fromJson(rawMsg) : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      status: json['status']?.toString() ?? ConversationStatus.accepted,
      requestedBy: json['requestedBy']?.toString(),
      isIncomingRequest: json['isIncomingRequest'] == true,
      isOutgoingRequest: json['isOutgoingRequest'] == true,
    );
  }
}
