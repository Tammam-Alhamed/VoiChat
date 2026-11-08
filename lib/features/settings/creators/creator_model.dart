class CreatorModel {
  final String id;
  final String name;
  final String profileId;
  final String profileImage;
  final bool isOnline;
  final String netAmount;
  final String agentEarnings;
  final String lastSeen;

  CreatorModel({
    required this.id,
    required this.name,
    required this.profileId,
    required this.profileImage,
    required this.isOnline,
    required this.netAmount,
    required this.agentEarnings,
    required this.lastSeen,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profileId: json['profile_id']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      isOnline: json['is_online'] == true,
      // Mapping database fields cleanly into UI metrics placeholders
      netAmount: json['wallet_balance'].toString() ?? "0.0",
      agentEarnings: json['total_earnings'] ?? "0.0",
      lastSeen: json['updated_at'] != null ? "Active" : "Offline",
    );
  }

  factory CreatorModel.mock(int index) {
    return CreatorModel(
      id: "dfs55545$index",
      name: "Placeholder Name $index",
      profileId: "dfs55545$index",
      profileImage: "",
      isOnline: index % 2 == 0,
      netAmount: " 1095.0",
      agentEarnings: "32.50",
      lastSeen: "12:00 am",
    );
  }
}
