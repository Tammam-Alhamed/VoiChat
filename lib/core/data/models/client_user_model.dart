import '../../domain/entities/client_user.dart';

/// JSON mapping for [ClientUser] (`GET /v1/users/clients` and similar).
/// `is_online` is injected by the backend from Redis on every response.
class ClientUserModel extends ClientUser {
  ClientUserModel({
    required super.id,
    required super.name,
    required super.profileImage,
    super.isVerified,
    super.isVip,
    super.isLive,
    super.isOnline,
    super.streams,
    super.followersCount,
    super.country,
    super.bio,
  });

  factory ClientUserModel.fromJson(Map<String, dynamic> json) {
    // The association alias is `liveStreams`. A missing key becomes an
    // empty list so `streams!` call sites never crash.
    final List<LiveStream> parsedStreams = json['liveStreams'] != null
        ? (json['liveStreams'] as List)
              .map((e) => LiveStreamModel.fromJson(e as Map<String, dynamic>))
              .toList()
        : [];

    return ClientUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profileImage: json['profile_image'].toString(),
      isVerified: json['is_verified'] == true,
      isVip: json['vip_member'] == true,
      isLive: json['is_live'] == true,
      isOnline: json['is_online'] == true,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      country: json['country']?.toString(),
      bio: json['bio']?.toString(),
      streams: parsedStreams,
    );
  }
}

/// JSON mapping for [LiveStream].
class LiveStreamModel extends LiveStream {
  const LiveStreamModel({
    required super.id,
    required super.roomName,
    required super.title,
    super.thumbnail,
    required super.viewersCount,
    required super.startedAt,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      viewersCount: (json['viewers_count'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'].toString())
          : DateTime.now(),
    );
  }
}
