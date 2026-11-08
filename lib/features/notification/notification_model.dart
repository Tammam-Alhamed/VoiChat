class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final String createdAt;
  final Sender? sender;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
      sender: json['sender'] != null ? Sender.fromJson(json['sender']) : null,
    );
  }
}

class Sender {
  final String id;
  final String name;
  final String? profileImage;

  Sender({required this.id, required this.name, this.profileImage});

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      profileImage: json['profile_image'],
    );
  }
}
