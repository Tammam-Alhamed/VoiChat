import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/widgets/app_state_view.dart';
import '../../../profile/profile_screen.dart';
import '../../../../core/widgets/premium_grid_card.dart';
import '../../../../core/domain/entities/client_user.dart';
import '../controllers/discover_controller.dart';
import '../../../live/presentation/controllers/live_entry_controller.dart';

/// Renders the content of a single home tab (Home / Live / Online / Country).
class HomeTabContent extends StatelessWidget {
  final String tabName;
  final bool showFilter;
  final VoidCallback? onFilterTap;

  const HomeTabContent({
    super.key,
    required this.tabName,
    this.showFilter = false,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showFilter) _CountryFilterBar(onTap: onFilterTap),
        Expanded(
          child: GetBuilder<DiscoverController>(
            builder: (viewModel) {
              final isLoading = viewModel.isTabLoading(tabName);
              final isEmpty = viewModel.isTabEmpty(tabName);
              final items = viewModel.dataForTab(tabName);

              if (isLoading && isEmpty) {
                return const _LoadingGrid();
              }

              if (isEmpty) {
                return RefreshIndicator(
                  color: const Color(0xFFB862E1),
                  onRefresh: () => viewModel.refreshTab(tabName),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * .7,
                        child: _EmptyState(tabName: tabName),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFFB862E1),
                onRefresh: () => viewModel.refreshTab(tabName),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _UserCard(user: items[index], index: index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Typed card ───────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final ClientUser user;
  final int index;
  const _UserCard({required this.user, required this.index});

  @override
  Widget build(BuildContext context) {
    return PremiumGridCard(
      bgUrl: user.profileImage,
      avatarUrl: user.profileImage,
      name: user.name,
      diamonds: user.followersCount.toString(),
      liveViews: user.streams!.isEmpty
          ? "0"
          : user.streams!.first.viewersCount.toString(),
      isLive: user.isLive,
      userId: user.id,
      index: index,
      isOnline: user.isOnline,
      viewsIconUrl: 'assets/icons/views.png',
      onTap: () {
        if (!user.isLive) {
          Get.to(
            TargetProfileScreen(
              userId: user.id,
              userName: user.name,
              userImage: user.profileImage,
              index: index,
            ),
          );
          return;
        }

        Get.find<LiveEntryController>().joinLiveStream(
          user.streams!.first,
          user,
        );
        return;
      },
    );
  }
}

// ─── Country filter bar ───────────────────────────────────────────────────────

class _CountryFilterBar extends StatelessWidget {
  final VoidCallback? onTap;
  const _CountryFilterBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
        child: GetBuilder<DiscoverController>(
          builder: (viewModel) {
            return InkWell(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FlagStack(selectedCountries: viewModel.selectedCountry),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color.fromARGB(255, 26, 26, 26),
                  ),
                  if (viewModel.selectedCountry != null) ...[
                    const SizedBox(width: 12),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _FlagStack extends StatelessWidget {
  final String? selectedCountries;
  const _FlagStack({this.selectedCountries});

  @override
  Widget build(BuildContext context) {
    final List<String> allCodes =
        (selectedCountries == null || selectedCountries!.isEmpty)
        ? ['US', 'SA', 'TR', 'LB', 'SY'] // Default 5 flags
        : selectedCountries!.split(',').map((e) => e.trim()).toList();

    const int maxVisible = 3;
    final int totalCount = allCodes.length;

    // We show up to maxVisible flags
    final List<String> visibleCodes = allCodes.take(maxVisible).toList();
    final int? remainder = totalCount > maxVisible
        ? (totalCount - maxVisible)
        : null;

    return SizedBox(
      height: 27,
      width: 27 + (visibleCodes.length - 1) * 18.0,
      child: Stack(
        children: [
          // Render Flags
          ...List.generate(visibleCodes.length, (index) {
            return Positioned(
              left: index * 18.0,
              child: _buildCircle(
                child: CountryFlag.fromCountryCode(visibleCodes[index]),
              ),
            );
          }),
          // Render Counter Overlay on the last flag if needed
          if (remainder != null && remainder > 0)
            Positioned(
              left: (visibleCodes.length - 1) * 18.0,
              child: _buildCircle(
                // Use a semi-transparent black overlay so the flag is still visible but text is readable
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Text(
                    '+$remainder',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircle({required Widget child, Color? color}) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}

// ─── Loading skeleton (per-tab shimmer) ────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tabName;
  const _EmptyState({required this.tabName});

  // Same empty layout for every home tab, just a title that names what
  // that specific tab actually shows nothing of.
  String get _title {
    switch (tabName) {
      case 'Live':
        return 'No live streams';
      case 'Online':
        return 'No online users yet';
      case 'Country':
        return 'No users found in this country';
      default:
        return 'No users found';
    }
  }

  @override
  Widget build(BuildContext context) {
    // No button here on purpose — the list is already wrapped in a
    // RefreshIndicator (see the ListView above), so "pull down to refresh"
    // is the one real way to refresh and the text just names that gesture
    // instead of duplicating it as a tappable action.
    return AppStateView.empty(title: _title, message: 'Pull down to refresh');
  }
}
