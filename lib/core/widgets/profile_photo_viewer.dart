import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../helpers/avatar_helper.dart';

/// Full-screen profile photo: pinch to zoom in/out, drag to move around,
/// double-tap to zoom, tap ✕ (or back) to close. Same look as the chat's
/// image viewer.
class ProfilePhotoViewer extends StatelessWidget {
  final String imageUrl;
  final Object? heroTag;

  const ProfilePhotoViewer({super.key, required this.imageUrl, this.heroTag});

  /// Opens the viewer if [imageUrl] is a real photo (not the default
  /// avatar). Returns false when there's nothing to show.
  static bool open(BuildContext context, String? imageUrl, {Object? heroTag}) {
    if (!AvatarHelper.hasRealPhoto(imageUrl)) return false;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) =>
            ProfilePhotoViewer(imageUrl: imageUrl!, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: heroTag == null
                ? null
                : PhotoViewHeroAttributes(tag: heroTag!),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 56,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
