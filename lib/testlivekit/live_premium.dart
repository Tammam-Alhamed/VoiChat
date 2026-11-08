import 'gifts_bottom_sheet.dart';

/// Premium state of one live session, as the server reports it.
/// [hasAccess] is about the current user (host, or a viewer who already sent
/// the entry gift in this session).
class LivePremiumInfo {
  final bool isPremium;
  final GiftItem? entryGift;
  final bool hasAccess;

  const LivePremiumInfo({
    required this.isPremium,
    this.entryGift,
    this.hasAccess = true,
  });

  static const off = LivePremiumInfo(isPremium: false);

  static LivePremiumInfo? fromJson(dynamic json) {
    if (json is! Map) return null;
    final gift = json['entryGift'];
    return LivePremiumInfo(
      isPremium: json['isPremium'] == true,
      entryGift: gift is Map<String, dynamic> ? GiftItem.fromJson(gift) : null,
      hasAccess: json['hasAccess'] != false,
    );
  }

  LivePremiumInfo copyWith({bool? isPremium, GiftItem? entryGift, bool? hasAccess}) {
    return LivePremiumInfo(
      isPremium: isPremium ?? this.isPremium,
      entryGift: entryGift ?? this.entryGift,
      hasAccess: hasAccess ?? this.hasAccess,
    );
  }
}
