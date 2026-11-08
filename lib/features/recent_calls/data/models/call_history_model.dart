import '../../domain/entities/call_history.dart';

/// JSON mapping for [CallHistory].
class CallHistoryModel extends CallHistory {
  const CallHistoryModel({
    required super.id,
    required super.callerId,
    required super.receiverId,
    required super.callType,
    required super.status,
    required super.roomName,
    required super.duration,
    required super.totalCost,
    required super.clientEarning,
    super.rating,
    super.ratingComment,
    super.startedAt,
    super.endedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.caller,
    required super.receiver,
  });

  factory CallHistoryModel.fromJson(Map<String, dynamic> json) {
    return CallHistoryModel(
      id: json['id'],
      callerId: json['caller_id'],
      receiverId: json['receiver_id'],
      callType: json['call_type'],
      status: json['status'],
      roomName: json['room_name'],
      duration: json['duration'],
      totalCost: json['total_cost'],
      clientEarning: json['client_earning'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      ratingComment: json['rating_comment'],
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      caller: CallParticipantModel.fromJson(json['caller']),
      receiver: CallParticipantModel.fromJson(json['receiver']),
    );
  }
}

/// JSON mapping for [CallParticipant].
class CallParticipantModel extends CallParticipant {
  const CallParticipantModel({
    required super.id,
    required super.name,
    super.profileImage,
    required super.isVerified,
  });

  factory CallParticipantModel.fromJson(Map<String, dynamic> json) {
    return CallParticipantModel(
      id: json['id'],
      name: json['name'],
      profileImage: json['profile_image'],
      isVerified: json['is_verified'],
    );
  }
}
