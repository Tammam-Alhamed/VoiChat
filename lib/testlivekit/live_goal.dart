/// A live gift goal, exactly as the server reports it. The server is the
/// single source of truth for progress and status; the app only displays it.
/// Each goal belongs to one live session ([liveSessionId]).
class LiveGoal {
  static const statusActive = 'active';
  static const statusCompleted = 'completed';

  final String id;
  final String liveSessionId;
  final int targetAmount;
  final num currentAmount;
  final String status;

  const LiveGoal({
    required this.id,
    required this.liveSessionId,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
  });

  bool get isCompleted => status == statusCompleted;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  /// Null for a missing / malformed payload (= no goal).
  static LiveGoal? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    final target = num.tryParse('${json['targetAmount']}');
    if (id == null || target == null) return null;
    return LiveGoal(
      id: id,
      liveSessionId: json['liveSessionId']?.toString() ?? '',
      targetAmount: target.toInt(),
      currentAmount: num.tryParse('${json['currentAmount']}') ?? 0,
      status: json['status']?.toString() ?? statusActive,
    );
  }
}
