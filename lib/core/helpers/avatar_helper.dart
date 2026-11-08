import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../assets_manager.dart';

/// Central place that decides whether a user has a "real" profile photo,
/// and resolves whatever the API gives us (null, empty string, a Google
/// profile photo URL, or a real uploaded photo URL) down to the right
/// [ImageProvider] — the bundled default silhouette in every case except a
/// real uploaded photo.
///
/// Two things count as "no real photo":
///  1. `null` / empty string — the person never set one.
///  2. A Google-hosted photo URL (`*.googleusercontent.com`, the domain
///     Google's OAuth `picture` claim always comes from) — that's a photo
///     the person never actually chose in this app, just whatever Google
///     auto-populated, so it's treated the same as "no photo" here.
class AvatarHelper {
  AvatarHelper._();

  /// True only when [url] is a photo the user actually chose in-app.
  static bool hasRealPhoto(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('googleusercontent.com')) return false;
    return true;
  }

  /// Resolves [url] to the right [ImageProvider] — the bundled default
  /// avatar when there's no real photo, otherwise a cached network image.
  static ImageProvider resolve(String? url) {
    if (!hasRealPhoto(url)) {
      return const AssetImage(AssetsManager.defaultProfileImage);
    }
    return CachedNetworkImageProvider(url!);
  }

  /// Same resolution, but as a ready-to-use widget for spots that build a
  /// plain `Image`/`CachedNetworkImage` instead of taking an ImageProvider
  /// (e.g. inside a `Container`'s `child`, or a full-screen viewer).
  static Widget widget(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (!hasRealPhoto(url)) {
      return Image.asset(
        AssetsManager.defaultProfileImage,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, _) => Image.asset(
        AssetsManager.defaultProfileImage,
        width: width,
        height: height,
        fit: fit,
      ),
      errorWidget: (context, _, __) => Image.asset(
        AssetsManager.defaultProfileImage,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
