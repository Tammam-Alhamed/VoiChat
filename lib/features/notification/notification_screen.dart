import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/widgets/app_state_view.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/helpers/avatar_helper.dart';
import '../settings/member_ship/member_ship_screen.dart';
import '../settings/recharge/recharge_screen.dart';
import '../settings/verify/verify_screen.dart';
import 'notifications_provider.dart';
import 'notification_model.dart';
import 'promo_card_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });

    // Pagination listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<NotificationsProvider>().loadMoreNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Simple time formatter based on your backend timestamps
  String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return "";
    try {
      final date = DateTime.parse(dateString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return "${difference.inDays}d ago";
      if (difference.inHours > 0) return "${difference.inHours}h ago";
      if (difference.inMinutes > 0) return "${difference.inMinutes}m ago";
      return "Just now";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }

  // Header Section (Unchanged)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                Icons.arrow_back,
                color: context.shellTextPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.shellTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "All your latest updates appear here",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, child) {
        // 1. Error State
        if (provider.pageState == PageState.error) {
          return AppStateView.error(
            message: provider.error,
            onRetry: () => provider.fetchNotifications(),
          );
        }

        // 2. Empty State — only when there's truly nothing to show (no
        // follow notifications AND no active promo cards).
        if (provider.pageState == PageState.empty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .7,
                  child: AppStateView.empty(
                    icon: Icons.notifications_off_outlined,
                    title: "No notifications yet",
                    message: "Pull down to refresh",
                  ),
                ),
              ],
            ),
          );
        }

        // 3. Loading & Loaded States (Handled seamlessly with Skeletonizer)
        final isLoading = provider.pageState == PageState.loading;

        // Create dummy list for the Skeletonizer if loading, else use real
        // data. Only follow notifications ever reach this screen now — the
        // page was simplified to just "new follower" + promo cards.
        final displayList = isLoading
            ? List.generate(
                7,
                (index) => NotificationModel(
                  id: '$index',
                  type: 'follow',
                  title: 'Loading skeleton title',
                  body: 'Skeleton subtitle here',
                  isRead: true,
                  createdAt: '',
                ),
              )
            : provider.notifications;

        // Promo cards (max 2, admin-controlled) render as the first items
        // in the same scrolling feed — skipped entirely during the loading
        // skeleton since we don't know yet whether any are active.
        final cards = isLoading ? const <PromoCardModel>[] : provider.promoCards;
        final cardCount = cards.length;
        final loaderCount = provider.isLoadMoreLoading ? 1 : 0;

        return Skeletonizer(
          enabled: isLoading,
          child: ListView.separated(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            itemCount: cardCount + displayList.length + loaderCount,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              if (index < cardCount) {
                return _buildPromoCard(cards[index]);
              }

              final notifIndex = index - cardCount;
              if (notifIndex == displayList.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7247EF),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final item = displayList[notifIndex];
              return _buildNotificationItem(item);
            },
          ),
        );
      },
    );
  }

  // Promo banner — image + title + short description, Tango-style. Tapping
  // opens the real in-app screen it's configured to point at.
  Widget _buildPromoCard(PromoCardModel card) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: GestureDetector(
        onTap: () => _openPromoDeepLink(card.deepLink),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: CachedNetworkImage(
                  imageUrl: card.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.description != null &&
                          card.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Resolves the admin-picked deep link to the real in-app screen. Kept as
  // a simple switch (rather than a URI-scheme deep-link package) since the
  // destination set is small and fixed.
  void _openPromoDeepLink(String deepLink) {
    switch (deepLink) {
      case 'svip':
        Get.to(() => const SVIPMembershipScreen());
        break;
      case 'verified':
        Get.to(() => const VerifiedAccountScreen());
        break;
      case 'recharge':
        Get.to(() => const RechargeCenterScreen());
        break;
    }
  }

  // Individual follow-notification row — this is the only notification
  // type the page shows now.
  Widget _buildNotificationItem(NotificationModel item) {
    final leadingWidget = CircleAvatar(
      radius: 24,
      backgroundImage: AvatarHelper.resolve(item.sender?.profileImage),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leadingWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                    color: context.shellTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.body != null)
                  Text(
                    item.body!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimeAgo(item.createdAt),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
