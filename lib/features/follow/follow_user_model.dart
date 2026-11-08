class FollowUserModel {
  final String id;
  final String name;
  final String profileImage;
  final bool isVerified;
  final bool vipMember;
  final bool isLive;

  /// I (the signed-in user) follow this person. Mutable: updated right away
  /// when the heart is tapped.
  bool isFollowing;

  /// This person follows me.
  final bool followsYou;

  /// Mutual follow → "Friends" + filled heart.
  bool get isFriend => isFollowing && followsYou;

  final String
  statusAsset; // fallback placeholder for original status UI assets

  FollowUserModel({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.isVerified,
    required this.vipMember,
    required this.isLive,
    this.isFollowing = false,
    this.followsYou = false,
    this.statusAsset = "assets/icons/status1.png",
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      vipMember: json['vip_member'] == true,
      isLive: json['is_live'] == true,
      isFollowing: json['is_following'] == true,
      followsYou: json['follows_you'] == true,
    );
  }

  factory FollowUserModel.mock(int index, String fallbackName) {
    return FollowUserModel(
      id: "mock_id_$index",
      name: "$fallbackName $index",
      profileImage: "",
      isVerified: false,
      vipMember: false,
      isLive: index % 2 == 0,
    );
  }
}
