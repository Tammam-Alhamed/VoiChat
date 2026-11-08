import '../../domain/entities/session_user.dart';

/// JSON mapping for [SessionUser].
class SessionUserModel extends SessionUser {
  SessionUserModel({
    required super.id,
    super.profileId,
    required super.name,
    super.email,
    super.phone,
    super.birthdate,
    super.birthdateUpdatedAt,
    super.bio,
    super.profileImage,
    super.country,
    required super.walletBalance,
    required super.role,
    required super.isLive,
    required super.isVerified,
    required super.vipMember,
    super.vipExpireDate,
    required super.followersCount,
    required super.followingCount,
    required super.totalEarnings,
    super.fcmToken,
    required super.isBanned,
    super.banReason,
    super.referredByProfileId,
    super.lastSeen,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SessionUserModel.fromJson(Map<String, dynamic> json) {
    return SessionUserModel(
      id: json['id'],
      profileId: json['profile_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      birthdateUpdatedAt: json['birthdate_updated_at'] != null
          ? DateTime.tryParse(json['birthdate_updated_at'].toString())
          : null,
      bio: json['bio'],
      profileImage: json['profile_image'],
      country: json['country'],
      referredByProfileId: json['referred_by_profile_id'],
      walletBalance: json['wallet_balance'].toString(),
      role: json['role'],
      isLive: json['is_live'] == true || json['is_live'] == 1,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      vipMember: json['vip_member'] == true || json['vip_member'] == 1,
      vipExpireDate: json['vip_expire_date'] != null
          ? DateTime.parse(json['vip_expire_date'])
          : null,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      totalEarnings: json['total_earnings'].toString(),
      fcmToken: json['fcm_token'],
      isBanned: json['is_banned'] == true || json['is_banned'] == 1,
      banReason: json['ban_reason'],
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Serialises a [SessionUser] for the local session snapshot.
extension SessionUserJson on SessionUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'email': email,
      'phone': phone,
      'birthdate': birthdate?.toIso8601String().split('T').first,
      'birthdate_updated_at': birthdateUpdatedAt?.toIso8601String(),
      'bio': bio,
      'profile_image': profileImage,
      'country': country,
      'wallet_balance': walletBalance,
      'role': role,
      'is_live': isLive,
      'is_verified': isVerified,
      'vip_member': vipMember,
      'vip_expire_date': vipExpireDate?.toIso8601String(),
      'followers_count': followersCount,
      'following_count': followingCount,
      'total_earnings': totalEarnings,
      'fcm_token': fcmToken,
      'is_banned': isBanned,
      'ban_reason': banReason,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
