import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/features/profile/profile_screen.dart';

class PremiumGridCard extends StatefulWidget {
  final String userId;
  final int index;
  final String bgUrl;
  final String avatarUrl;
  final String name;
  final String liveViews;
  final String diamonds;
  final bool isLive;
  final bool isOnline;
  final String viewsIconUrl;
  final VoidCallback onTap;

  const PremiumGridCard({
    super.key,
    required this.bgUrl,
    required this.userId,
    required this.index,
    required this.avatarUrl,
    required this.name,
    required this.liveViews,
    required this.isLive,
    this.isOnline = false,
    required this.viewsIconUrl,
    required this.onTap,
    required this.diamonds,
  });

  @override
  State<PremiumGridCard> createState() => _PremiumGridCardState();
}

class _PremiumGridCardState extends State<PremiumGridCard> {
  bool _isPressed = false;

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    }
    // Users with no profile photo yet come back from the API with
    // profile_image: "" — AssetImage('') has nothing to load and throws
    // "Unable to load asset: ''" on every frame. Fall back to the bundled
    // placeholder instead of trying to load an empty path.
    if (url.isEmpty) {
      return const AssetImage(AssetsManager.defaultProfileImage);
    }
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _getImageProvider(widget.bgUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                if (widget.isLive)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            widget.viewsIconUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.liveViews,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 27, 27),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        InkWell(
                          onTap: () {
                            Get.to(
                              TargetProfileScreen(
                                userId: widget.userId,
                                userName: widget.name,
                                userImage: widget.avatarUrl,
                                index: widget.index,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              widget.isOnline && !widget.isLive
                                  ? CircleAvatar(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        2,
                                        248,
                                        22,
                                      ),
                                      radius: 15,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.grey[100],
                                        radius: 14,
                                        backgroundImage: AvatarHelper.resolve(
                                          widget.avatarUrl,
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.grey[100],
                                      backgroundImage: AvatarHelper.resolve(
                                        widget.avatarUrl,
                                      ),
                                    ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: "Roboto",
                                      ),
                                      maxLines: 1,
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.diamond,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          widget.diamonds,
                                          style: const TextStyle(
                                            color: Color(0xFFBBBBBB),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
