/// One entry of the user's call history.
class CallHistory {
  final String id;
  final String callerId;
  final String receiverId;
  final String callType;
  final String status;
  final String roomName;
  final int duration;
  final String totalCost;
  final String clientEarning;
  final double? rating;
  final String? ratingComment;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CallParticipant caller;
  final CallParticipant receiver;

  const CallHistory({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    required this.roomName,
    required this.duration,
    required this.totalCost,
    required this.clientEarning,
    this.rating,
    this.ratingComment,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.caller,
    required this.receiver,
  });
}

/// The caller or receiver of a call history entry.
class CallParticipant {
  final String id;
  final String name;
  final String? profileImage;
  final bool isVerified;

  const CallParticipant({
    required this.id,
    required this.name,
    this.profileImage,
    required this.isVerified,
  });
}
