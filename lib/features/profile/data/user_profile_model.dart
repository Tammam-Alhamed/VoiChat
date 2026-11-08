import 'post_model.dart';

class UserProfile {
  final String id;
  final String profileId;
  final String name;
  final String? email;
  final String? phone;
  final String? birthdate;
  final String? bio;
  final String? profileImage;
  final String country;
  final String walletBalance;
  final String role;

  final bool isLive;
  final bool isVerified;
  final bool vipMember;

  final String? vipExpireDate;

  int followersCount;
  final int followingCount;

  final String totalEarnings;

  final String? fcmToken;

  final bool isBanned;
  final String? banReason;

  final String? lastSeen;
  final String createdAt;
  final String updatedAt;

  final List<PostModel> posts;

  bool isFollowing;
  final bool isBlocked;
  final bool isOnline;

  UserProfile({
    required this.id,
    required this.profileId,
    required this.name,
    this.email,
    this.phone,
    this.birthdate,
    this.bio,
    this.profileImage,
    required this.country,
    required this.walletBalance,
    required this.role,
    required this.isLive,
    required this.isVerified,
    required this.vipMember,
    this.vipExpireDate,
    required this.followersCount,
    required this.followingCount,
    required this.totalEarnings,
    this.fcmToken,
    required this.isBanned,
    this.banReason,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.posts,
    required this.isFollowing,
    required this.isBlocked,
    required this.isOnline,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      profileId: json['profile_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      birthdate: json['birthdate'],
      bio: json['bio'],
      profileImage: json['profile_image'],
      country: json['country'],
      walletBalance: json['wallet_balance'].toString(),
      role: json['role'],
      isLive: json['is_live'],
      isVerified: json['is_verified'],
      vipMember: json['vip_member'],
      vipExpireDate: json['vip_expire_date'],
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      totalEarnings: json['total_earnings'].toString(),
      fcmToken: json['fcm_token'],
      isBanned: json['is_banned'],
      banReason: json['ban_reason'],
      lastSeen: json['last_seen'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      posts: (json['posts'] as List<dynamic>? ?? [])
          .map((e) => PostModel.fromJson(e))
          .toList(),
      isFollowing: json['is_following'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'profile_id': profileId,
    'name': name,
    'email': email,
    'phone': phone,
    'birthdate': birthdate,
    'bio': bio,
    'profile_image': profileImage,
    'country': country,
    'wallet_balance': walletBalance,
    'role': role,
    'is_live': isLive,
    'is_verified': isVerified,
    'vip_member': vipMember,
    'vip_expire_date': vipExpireDate,
    'followers_count': followersCount,
    'following_count': followingCount,
    'total_earnings': totalEarnings,
    'fcm_token': fcmToken,
    'is_banned': isBanned,
    'ban_reason': banReason,
    'last_seen': lastSeen,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'posts': posts.map((e) => e.toJson()).toList(),
    'is_following': isFollowing,
    'is_blocked': isBlocked,
    'is_online': isOnline,
  };
}
