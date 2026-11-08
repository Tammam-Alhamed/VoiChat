/// Data models for the call feature.
///
/// Mirrors the backend Call model and API response shapes.

class CallModel {
  final String id;
  final String callerId;
  final String receiverId;
  final String callType; // 'audio' | 'video'
  final String roomName;
  final String status; // 'ringing' | 'answered' | 'ended' | 'missed' | 'declined'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration; // seconds
  final double totalCost;
  final double clientEarning;
  final int? rating;
  final String? ratingComment;
  final DateTime createdAt;

  CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.roomName,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration = 0,
    this.totalCost = 0,
    this.clientEarning = 0,
    this.rating,
    this.ratingComment,
    required this.createdAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id']?.toString() ?? '',
      callerId: json['caller_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      callType: json['call_type']?.toString() ?? 'audio',
      roomName: json['room_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      totalCost: (json['total_cost'] is num)
          ? (json['total_cost'] as num).toDouble()
          : double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0,
      clientEarning: (json['client_earning'] is num)
          ? (json['client_earning'] as num).toDouble()
          : double.tryParse(json['client_earning']?.toString() ?? '0') ?? 0,
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating']?.toString() ?? ''),
      ratingComment: json['rating_comment']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Response from POST /calls/initiate
class CallInitiateResponse {
  final CallModel call;
  final String callerToken;
  final String receiverToken;
  final String roomName;

  CallInitiateResponse({
    required this.call,
    required this.callerToken,
    required this.receiverToken,
    required this.roomName,
  });

  factory CallInitiateResponse.fromJson(Map<String, dynamic> json) {
    return CallInitiateResponse(
      call: CallModel.fromJson(json['call'] ?? {}),
      callerToken: json['callerToken']?.toString() ?? '',
      receiverToken: json['receiverToken']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
    );
  }
}

/// Response from POST /calls/:id/answer
class CallAnswerResponse {
  final CallModel call;
  final String token;
  final String roomName;

  CallAnswerResponse({
    required this.call,
    required this.token,
    required this.roomName,
  });

  factory CallAnswerResponse.fromJson(Map<String, dynamic> json) {
    return CallAnswerResponse(
      call: CallModel.fromJson(json['call'] ?? {}),
      token: json['token']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
    );
  }
}

/// Simplified user info attached to call history items.
class CallUserInfo {
  final String id;
  final String name;
  final String? profileImage;
  final bool isVerified;

  CallUserInfo({
    required this.id,
    required this.name,
    this.profileImage,
    this.isVerified = false,
  });

  factory CallUserInfo.fromJson(Map<String, dynamic> json) {
    return CallUserInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      isVerified: json['is_verified'] == true,
    );
  }
}

/// Call history item with embedded user info.
class CallHistoryItem {
  final CallModel call;
  final CallUserInfo? caller;
  final CallUserInfo? receiver;

  CallHistoryItem({
    required this.call,
    this.caller,
    this.receiver,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      call: CallModel.fromJson(json),
      caller: json['caller'] != null
          ? CallUserInfo.fromJson(json['caller'])
          : null,
      receiver: json['receiver'] != null
          ? CallUserInfo.fromJson(json['receiver'])
          : null,
    );
  }
}
