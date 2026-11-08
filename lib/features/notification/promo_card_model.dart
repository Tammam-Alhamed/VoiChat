/// Admin-managed promotional banner shown at the top of the notifications
/// feed (see PromoCard model on the backend). The backend only ever hands
/// back cards that are currently active AND inside their display window,
/// capped at 2 — so this model doesn't need to know about duration/expiry
/// at all, just what to render and where tapping it should go.
class PromoCardModel {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;

  /// One of 'svip' | 'verified' | 'recharge' — resolved to a concrete
  /// screen by the notifications screen's deep-link switch.
  final String deepLink;

  PromoCardModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.deepLink,
  });

  factory PromoCardModel.fromJson(Map<String, dynamic> json) {
    return PromoCardModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      deepLink: json['deep_link']?.toString() ?? '',
    );
  }
}
