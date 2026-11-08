/// The signed-in user as the app keeps it in memory. A few fields are
/// mutable because screens update them locally (name, bio, photo, contact
/// details) right after a successful edit, before the next server sync.
class SessionUser {
  final String id;
  final String? profileId;
  String name;
  String? email;
  String? phone;
  DateTime? birthdate;

  /// Last time the birthdate was set or changed (it can change once every
  /// six months). Null means it may change now.
  DateTime? birthdateUpdatedAt;
  String? bio;
  String? profileImage;
  String? country;
  String walletBalance;
  String role;
  bool isLive;
  bool isVerified;
  bool vipMember;
  DateTime? vipExpireDate;
  int followersCount;
  int followingCount;
  String totalEarnings;
  String? fcmToken;
  bool isBanned;
  String? banReason;
  String? referredByProfileId;
  DateTime? lastSeen;
  DateTime createdAt;
  DateTime updatedAt;

  SessionUser({
    required this.id,
    this.profileId,
    required this.name,
    this.email,
    this.phone,
    this.birthdate,
    this.birthdateUpdatedAt,
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
    this.referredByProfileId,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });
}
