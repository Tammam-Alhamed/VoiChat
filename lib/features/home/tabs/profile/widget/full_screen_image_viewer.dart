import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String? imageUrl;
  const FullScreenImageViewer({super.key, this.imageUrl});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _baseScale = 1.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller)
      ..addListener(() => setState(() => _scale = _animation.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = AvatarHelper.resolve(widget.imageUrl);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      onScaleStart: (details) {
        _controller.stop();
        _baseScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() => _scale = (_baseScale * details.scale).clamp(0.6, 3.0));
      },
      onScaleEnd: (details) {
        _animation = Tween<double>(
          begin: _scale,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward(from: 0);
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: imageProvider, fit: BoxFit.cover),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
            Center(
              child: Hero(
                tag: "profile_image",
                child: Transform.scale(
                  scale: _scale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 25,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
