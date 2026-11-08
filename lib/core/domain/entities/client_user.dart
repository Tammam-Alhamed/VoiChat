/// A user as shown on discovery cards (home tabs, followings, search).
/// [isLive], [isOnline] and [streams] change in place when realtime
/// presence events arrive.
class ClientUser {
  final String id;
  final String name;
  final String profileImage;
  final bool isVerified;
  final bool isVip;
  bool isLive;
  bool isOnline;
  final int followersCount;
  final String? country;
  final String? bio;
  final List<LiveStream>? streams;

  ClientUser({
    required this.id,
    required this.name,
    required this.profileImage,
    this.isVerified = false,
    this.isVip = false,
    this.isLive = false,
    this.isOnline = false,
    this.streams,
    this.followersCount = 0,
    this.country,
    this.bio,
  });
}

/// A live broadcast currently running for a user.
class LiveStream {
  final String id;
  final String roomName;
  final String title;
  final String? thumbnail;
  final int viewersCount;
  final DateTime startedAt;

  const LiveStream({
    required this.id,
    required this.roomName,
    required this.title,
    this.thumbnail,
    required this.viewersCount,
    required this.startedAt,
  });
}
