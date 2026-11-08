class PostModel {
  final String id;
  final String userId;
  final String mediaType;
  final String mediaUrl;
  final String? thumbnail;
  final String createdAt;
  final String updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      mediaType: json['media_type'],
      mediaUrl: json['media_url'],
      thumbnail: json['thumbnail'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'media_type': mediaType,
    'media_url': mediaUrl,
    'thumbnail': thumbnail,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
