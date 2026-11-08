/// What the server returns when the user enters a live room, either as the
/// host (start or resume) or as a viewer (join).
///
/// The room screens read nested pieces (goal, premium info, stream row), so
/// the original payload is kept in [raw] and exposed through typed getters.
class LiveSessionAccess {
  final Map<String, dynamic> raw;

  const LiveSessionAccess(this.raw);

  Map<String, dynamic> get liveStream =>
      (raw['liveStream'] as Map<String, dynamic>?) ?? const {};

  dynamic get token => raw['token'];

  /// Room name; the start and resume endpoints send it at the top level.
  dynamic get roomName => raw['roomName'] ?? liveStream['room_name'];

  dynamic get goal => raw['goal'];

  dynamic get premium => raw['premium'];

  num get totalGiftsValue =>
      num.tryParse('${liveStream['total_gifts_value']}') ?? 0;

  bool get callsOff =>
      liveStream['calls_off'] == true || liveStream['calls_off'] == 1;
}
