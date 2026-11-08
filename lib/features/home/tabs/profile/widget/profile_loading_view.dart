import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/themes/app_dark_colors.dart';
import '../../../../../core/widgets/app_state_view.dart';

/// Shown while [ProfileTabViewModel.pageState] is [PageState.loading].
///
/// Mirrors the shape of the loaded profile screen (avatar, name line,
/// stats row, bio, button, tabs, grid) so the shimmer placeholder lines up
/// with the real content once it loads in.
class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Text(
                      'ID: 000000',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),

                    const Icon(Icons.share, size: 20),
                    const SizedBox(width: 18),
                    const Icon(Icons.settings, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Avatar + name + location
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: context.shellAvatarPlaceholder,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Placeholder Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Placeholder Country',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatSkeleton(),
                    _StatSkeleton(),
                    _StatSkeleton(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Bio
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 33),
                child: Text(
                  'This is a placeholder bio line that wraps a bit.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
              // Add post button
              Center(
                child: Container(
                  width: 235,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.shellSkeleton,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_on, size: 24),
                    SizedBox(width: MediaQuery.of(context).size.width / 3),
                    const Icon(Icons.grid_on, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Grid placeholder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.9,
                ),
                itemCount: 6,
                itemBuilder: (context, index) =>
                    Container(color: context.shellSkeleton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '000',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text('Label', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Shown while [ProfileTabViewModel.pageState] is [PageState.error].
class ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppStateView.error(message: message, onRetry: onRetry),
    );
  }
}

/// Shown while [ProfileTabViewModel.pageState] is [PageState.empty]
/// (the profile endpoint returned successfully but with no data).
class ProfileEmptyView extends StatelessWidget {
  final VoidCallback onRetry;

  const ProfileEmptyView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppStateView.empty(
        icon: Icons.person_off_outlined,
        title: 'No profile data',
        message: "We couldn't find any profile data for your account.",
        actionLabel: 'Retry',
        onGoBack: onRetry,
      ),
    );
  }
}
