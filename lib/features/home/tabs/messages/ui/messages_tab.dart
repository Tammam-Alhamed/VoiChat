import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/themes/app_dark_colors.dart';
import '../../../../../core/helpers/avatar_helper.dart';
import '../../../../../core/widgets/app_search_field.dart';
import '../../../../chat/chat_screen.dart';
import '../../../../profile/profile_screen.dart';
import '../../../presentation/controllers/navigation_controller.dart';
import '../models/conversation_model.dart';
import '../viewmodel/messages_tab_viewmodel.dart';
import 'message_requests_screen.dart';

import '../../../../session/presentation/controllers/session_controller.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  MessagesTabState createState() => MessagesTabState();
}

class MessagesTabState extends State<MessagesTab>
    with TickerProviderStateMixin {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ─── Selection state ──────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SessionController>().setUnSeenMessagesZero();
      context.read<MessagesTabViewModel>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Toolbar actions ──────────────────────────────────────────────────────

  void _deleteSelected() {
    context.read<MessagesTabViewModel>().deleteConversations(_selectedIds);
    setState(() => _selectedIds.clear());
  }

  void _pinSelected(bool pin) {
    final provider = context.read<MessagesTabViewModel>();
    for (final id in _selectedIds) {
      final conv = provider.conversations.firstWhere(
        (c) => c.id == id,
        orElse: () => throw StateError('not found'),
      );
      if (conv.isPinned != pin) provider.togglePin(id);
    }
    setState(() => _selectedIds.clear());
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return timeago.format(dt, locale: 'en_short');
  }

  String _lastMessagePreview(ConversationModel conv) {
    final msg = conv.lastMessage;
    if (msg == null) return 'Say hello 👋';
    switch (msg.messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎙 Voice message';
      default:
        return msg.content ?? '';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavigationController>(
      builder: (navProvider) {
        bool isActive = navProvider.currentIndex == 1;

        return TweenAnimationBuilder<double>(
          key: ValueKey(isActive),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildPageContent(),
        );
      },
    );
  }

  Widget _buildPageContent() {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated header / toolbar
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuart,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isSelectionMode
                  ? _buildSelectionToolbar()
                  : _buildNormalHeader(),
            ),

            Divider(color: context.shellDivider, thickness: 1, height: 1),
            const SizedBox(height: 16),

            // Online users / story row
            SizedBox(
              height: 100,
              child: Consumer<MessagesTabViewModel>(
                builder: (context, provider, _) {
                  if (provider.suggestedLoading) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 6,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: context.shellSkeleton,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 50,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: context.shellSkeleton,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  final clients = provider.suggestedClients;
                  if (clients.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: context.themedColor(
                          const Color(0xFFF8F9FA),
                          AppDarkColors.card,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.themedColor(
                            const Color(0xFFF0F0F0),
                            AppDarkColors.border,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.themedColor(
                                Colors.white,
                                AppDarkColors.surface,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.history_toggle_off,
                              color: context.themedColor(
                                const Color(0xFFB0B0B0),
                                AppDarkColors.textSecondary,
                              ),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Quiet right now",
                                style: TextStyle(
                                  color: context.themedColor(
                                    Colors.black87,
                                    AppDarkColors.textPrimary,
                                  ),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "No active friends to show",
                                style: TextStyle(
                                  color: context.themedColor(
                                    const Color(0xFF9E9E9E),
                                    AppDarkColors.textSecondary,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final user = clients[index];
                      return _buildAnimatedStory(
                        index,
                        name: user.name,
                        imageUrl: user.profileImage,
                        isLive: user.isLive,
                        onTap: () => Get.to(
                          () => ChatScreen(
                            receiverId: user.id,
                            userName: user.name,
                            userAvatar: user.profileImage,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: AppSearchField(
                controller: _searchController,
                hintText: "search messages ...",
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),

            // Dynamic chat list
            Expanded(
              child: Consumer<MessagesTabViewModel>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.conversations.isEmpty) {
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: 8,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: context.shellSkeleton,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: context.shellSkeleton,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: context.shellSkeleton,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 35,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: context.shellSkeleton,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  final filtered = searchQuery.isEmpty
                      ? provider.conversations
                      : provider.conversations
                            .where(
                              (c) => c.otherUser.name.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    // No refresh button — pull down to refresh instead, same
                    // as every other empty state in the app.
                    return RefreshIndicator(
                      color: const Color(0xFF7B13E2),
                      onRefresh: provider.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * .7,
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.9 + (0.1 * value),
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7B13E2,
                                        ).withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF7B13E2,
                                            ).withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.forum_rounded,
                                            size: 32,
                                            color: Color(0xFF7B13E2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'No Messages Yet'
                                          : 'No Results Found',
                                      style: TextStyle(
                                        color: context.themedColor(
                                          const Color(0xFF2D2D2D),
                                          AppDarkColors.textPrimary,
                                        ),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'Start a conversation and connect\nwith your friends!'
                                          : 'We couldn\'t find any messages\nmatching "$searchQuery".',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: context.themedColor(
                                          const Color(0xFF8C8C8C),
                                          AppDarkColors.textSecondary,
                                        ),
                                        fontSize: 15,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    if (searchQuery.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      TextButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => searchQuery = '');
                                        },
                                        icon: const Icon(
                                          Icons.clear_all,
                                          color: Color(0xFF7B13E2),
                                        ),
                                        label: const Text(
                                          'Clear Search',
                                          style: TextStyle(
                                            color: Color(0xFF7B13E2),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          backgroundColor: const Color(
                                            0xFF7B13E2,
                                          ).withOpacity(0.08),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Pull down to refresh',
                                        style: TextStyle(
                                          color: context.themedColor(
                                            const Color(0xFF8C8C8C),
                                            AppDarkColors.textSecondary,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF7B13E2),
                    onRefresh: provider.refresh,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        final isSelected = _selectedIds.contains(conv.id);
                        final isTyping = provider.isTyping(conv.id);
                        return _buildAnimatedChatItem(
                          index: index,
                          conv: conv,
                          isSelected: isSelected,
                          isTyping: isTyping,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Normal Header ────────────────────────────────────────────────────────

  Widget _buildNormalHeader() {
    return Padding(
      key: const ValueKey('normal_header'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Messages",
            style: TextStyle(
              color: context.shellTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRequestsButton(),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: context.shellTextPrimary),
            ],
          ),
        ],
      ),
    );
  }

  // Opens the "Message requests" inbox; the badge counts requests waiting
  // for my answer.
  Widget _buildRequestsButton() {
    return Consumer<MessagesTabViewModel>(
      builder: (context, provider, _) {
        final count = provider.requestsCount;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Get.to(() => const MessageRequestsScreen()),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.mark_chat_unread_outlined,
                  color: context.shellTextPrimary,
                ),
                if (count > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B13E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.shellBackground,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Selection Toolbar ────────────────────────────────────────────────────

  Widget _buildSelectionToolbar() {
    return Container(
      key: const ValueKey('selection_header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: context.shellBackground,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: context.shellTextPrimary),
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
          const SizedBox(width: 8),
          Text(
            "${_selectedIds.length} Selected",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.shellTextPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.push_pin_outlined,
              color: context.shellTextSecondary,
            ),
            tooltip: "Pin",
            onPressed: () => _pinSelected(true),
          ),
          IconButton(
            icon: Icon(
              Icons.do_not_disturb_off_outlined,
              color: context.shellTextSecondary,
            ),
            tooltip: "Unpin",
            onPressed: () => _pinSelected(false),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Delete",
            onPressed: _deleteSelected,
          ),
        ],
      ),
    );
  }

  // ─── Animated Story ───────────────────────────────────────────────────────

  Widget _buildAnimatedStory(
    int index, {
    required String name,
    String? imageUrl,
    bool isLive = false,
    VoidCallback? onTap,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        );
      },
      child: _buildStoryItem(
        name: name,
        imageUrl: imageUrl,
        isLive: isLive,
        onTap: onTap,
      ),
    );
  }

  Widget _buildStoryItem({
    required String name,
    String? imageUrl,
    bool isLive = false,
    VoidCallback? onTap,
  }) {
    final ImageProvider avatarImage = AvatarHelper.resolve(imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.shellAvatarPlaceholder,
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFFFF3A54)
                          : Colors.transparent,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: avatarImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3A54),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(color: context.shellTextPrimary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Animated Chat Item ───────────────────────────────────────────────────

  Widget _buildAnimatedChatItem({
    required int index,
    required ConversationModel conv,
    required bool isSelected,
    required bool isTyping,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 350 + (index * 40)),
      curve: Curves.easeOutQuart,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildChatItemUI(conv, isSelected, isTyping),
    );
  }

  Widget _buildChatItemUI(
    ConversationModel conv,
    bool isSelected,
    bool isTyping,
  ) {
    final user = conv.otherUser;
    final hasUnread = conv.unreadCount > 0;
    final previewText = isTyping ? 'Typing...' : _lastMessagePreview(conv);
    final avatarProvider = AvatarHelper.resolve(user.profileImage);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      color: isSelected
          ? const Color(0xFF4CAF50).withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onLongPress: () {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(conv.id);
            } else {
              _selectedIds.add(conv.id);
            }
          });
        },
        onTap: () {
          if (isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(conv.id);
              } else {
                _selectedIds.add(conv.id);
              }
            });
          } else {
            context.read<MessagesTabViewModel>().clearUnread(conv.id);
            Get.to(
              () => ChatScreen(
                receiverId: user.id,
                userName: user.name,
                userAvatar: user.profileImage,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!isSelectionMode) {
                    Get.to(
                      () => TargetProfileScreen(
                        userId: user.id,
                        userName: user.name,
                        userImage: user.profileImage,
                        index: 0,
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 55,
                  height: 55,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Stack(
                      children: [
                        Container(
                          key: const ValueKey('unselected'),
                          decoration: BoxDecoration(
                            color: context.shellAvatarPlaceholder,
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: avatarProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            bottom: 0,
                            right: 2,
                            child: Container(
                              key: const ValueKey('selected'),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (conv.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: context.themedColor(
                              const Color(0xFF7A7A7A),
                              AppDarkColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isTyping || hasUnread
                            ? context.shellTextPrimary
                            : context.themedColor(
                                const Color(0xFF7A7A7A),
                                AppDarkColors.textSecondary,
                              ),
                        fontSize: 14,
                        fontStyle: isTyping
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conv.updatedAt),
                    style: TextStyle(
                      color: context.themedColor(
                        const Color(0xFF9E9E9E),
                        AppDarkColors.textSecondary,
                      ),
                      fontSize: 12,
                    ),
                  ),
                  if (hasUnread && !isSelected) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B13E2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conv.unreadCount > 99
                            ? '99+'
                            : conv.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
