class BlockedUser {
  final String id;
  final String name;
  final String? profileImage;

  BlockedUser({required this.id, required this.name, this.profileImage});

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profileImage: json['profile_image'],
    );
  }
}
