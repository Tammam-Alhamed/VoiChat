class MyProfileResponse {
  final bool success;
  final String message;
  UserProfile? data;

  MyProfileResponse({required this.success, required this.message, this.data});

  factory MyProfileResponse.fromJson(Map<String, dynamic> json) {
    return MyProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
  };
}

class UserProfile {
  final String id;
  final String profileId;
  final String name;
  final String? email;
  final String phone;
  final String? birthdate;
  final String? bio;
  final String? profileImage;
  final String? country;
  final String walletBalance;
  final String role;
  final bool isLive;
  final bool isVerified;
  final bool vipMember;
  final String? vipExpireDate;
  final int followersCount;
  final int followingCount;
  final String totalEarnings;
  final String? fcmToken;
  final bool isBanned;
  final String? banReason;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOnline;
  final List<Post> posts;

  UserProfile({
    required this.id,
    required this.profileId,
    required this.name,
    this.email,
    required this.phone,
    this.birthdate,
    this.bio,
    this.profileImage,
    this.country,
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
    this.createdAt,
    this.updatedAt,
    required this.isOnline,
    required this.posts,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      profileId: json['profile_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      birthdate: json['birthdate'],
      bio: json['bio'],
      profileImage: json['profile_image'],
      country: json['country'],
      walletBalance: json['wallet_balance'] ?? '0',
      role: json['role'] ?? '',
      isLive: json['is_live'] ?? false,
      isVerified: json['is_verified'] ?? false,
      vipMember: json['vip_member'] ?? false,
      vipExpireDate: json['vip_expire_date'],
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      totalEarnings: json['total_earnings'] ?? '0',
      fcmToken: json['fcm_token'],
      isBanned: json['is_banned'] ?? false,
      banReason: json['ban_reason'],
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isOnline: json['is_online'] ?? false,
      posts:
          (json['posts'] as List<dynamic>?)
              ?.map((e) => Post.fromJson(e))
              .toList() ??
          [],
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
    'last_seen': lastSeen?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'is_online': isOnline,
    'posts': posts.map((e) => e.toJson()).toList(),
  };
}

class Post {
  final String id;
  final String userId;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Post({
    required this.id,
    required this.userId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnail,
    this.createdAt,
    this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      mediaType: json['media_type'] ?? '',
      mediaUrl: json['media_url'] ?? '',
      thumbnail: json['thumbnail'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'media_type': mediaType,
    'media_url': mediaUrl,
    'thumbnail': thumbnail,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
