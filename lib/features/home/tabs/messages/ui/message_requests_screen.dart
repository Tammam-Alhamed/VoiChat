import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/helpers/avatar_helper.dart';
import '../../../../../core/helpers/toast_helper.dart';
import '../../../../../core/themes/app_dark_colors.dart';
import '../../../../chat/chat_screen.dart';
import '../models/conversation_model.dart';
import '../viewmodel/messages_tab_viewmodel.dart';

/// "Message requests" inbox. Conversations someone started with me land here
/// (Received) until I reply or tap Accept; requests I started wait under
/// Sent until the other person accepts. Accepted ones move to the normal
/// Messages list.
class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  static const _accent = Color(0xFF7B13E2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesTabViewModel>().fetchRequests();
    });
  }

  String _preview(ConversationModel conv) {
    final msg = conv.lastMessage;
    if (msg == null) return '';
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

  void _openChat(ConversationModel conv) {
    Get.to(
      () => ChatScreen(
        receiverId: conv.otherUser.id,
        userName: conv.otherUser.name,
        userAvatar: conv.otherUser.profileImage,
      ),
    );
  }

  Future<void> _accept(ConversationModel conv) async {
    final ok = await context.read<MessagesTabViewModel>().acceptRequest(
      conv.id,
    );
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccessToast(
        message: 'You can now chat with ${conv.otherUser.name}',
      );
    } else {
      ToastHelper.showErrorToast(message: 'Failed to accept request');
    }
  }

  Future<void> _remove(ConversationModel conv, {required bool sent}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          sent ? 'Cancel request' : 'Delete request',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          sent
              ? 'Your messages to ${conv.otherUser.name} will be deleted.'
              : 'The request from ${conv.otherUser.name} and its messages will be deleted. They won\'t be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              sent ? 'Cancel request' : 'Delete',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<MessagesTabViewModel>().removeRequest(
      conv.id,
    );
    if (!mounted) return;
    if (!ok) ToastHelper.showErrorToast(message: 'Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.shellBackground,
        appBar: AppBar(
          backgroundColor: context.shellBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: context.shellTextPrimary),
          title: Text(
            'Message requests',
            style: TextStyle(
              color: context.shellTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            indicatorColor: _accent,
            labelColor: _accent,
            unselectedLabelColor: context.shellTextSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Consumer<MessagesTabViewModel>(
                builder: (context, vm, _) => Tab(
                  text: vm.requestsCount > 0
                      ? 'Received (${vm.requestsCount})'
                      : 'Received',
                ),
              ),
              const Tab(text: 'Sent'),
            ],
          ),
        ),
        body: Consumer<MessagesTabViewModel>(
          builder: (context, vm, _) {
            return TabBarView(
              children: [
                _buildList(
                  vm,
                  vm.receivedRequests,
                  sent: false,
                  emptyTitle: 'No message requests',
                  emptyText:
                      'When someone you don\'t chat with yet messages you, it shows up here.',
                ),
                _buildList(
                  vm,
                  vm.sentRequests,
                  sent: true,
                  emptyTitle: 'No pending requests',
                  emptyText:
                      'Messages you send to new people wait here until they accept.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    MessagesTabViewModel vm,
    List<ConversationModel> items, {
    required bool sent,
    required String emptyTitle,
    required String emptyText,
  }) {
    if (vm.requestsLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: vm.fetchRequests,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .6,
                  child: _buildEmpty(emptyTitle, emptyText),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (context, index) {
                if (index == 0) return _buildHint(sent);
                return _buildRow(items[index - 1], sent: sent);
              },
            ),
    );
  }

  Widget _buildHint(bool sent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        sent
            ? 'They\'ll see your messages in their requests. You can send up to 5 text messages until they accept.'
            : 'Open a request to read it. They won\'t know you\'ve seen it until you accept or reply.',
        style: TextStyle(color: context.shellTextSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildRow(ConversationModel conv, {required bool sent}) {
    final user = conv.otherUser;
    final hasUnread = !sent && conv.unreadCount > 0;

    return InkWell(
      onTap: () => _openChat(conv),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.shellAvatarPlaceholder,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AvatarHelper.resolve(user.profileImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.shellTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _preview(conv),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? context.shellTextPrimary
                          : context.themedColor(
                              const Color(0xFF7A7A7A),
                              AppDarkColors.textSecondary,
                            ),
                      fontWeight: hasUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (conv.updatedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(conv.updatedAt!, locale: 'en_short'),
                      style: TextStyle(
                        color: context.shellTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (sent)
              TextButton(
                onPressed: () => _remove(conv, sent: true),
                style: TextButton.styleFrom(
                  foregroundColor: context.shellTextSecondary,
                ),
                child: const Text('Cancel'),
              )
            else ...[
              _roundAction(
                icon: Icons.close,
                color: Colors.redAccent,
                tooltip: 'Delete',
                onTap: () => _remove(conv, sent: false),
              ),
              const SizedBox(width: 8),
              _roundAction(
                icon: Icons.check,
                color: _accent,
                tooltip: 'Accept',
                filled: true,
                onTap: () => _accept(conv),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.4),
          ),
          child: Icon(icon, size: 20, color: filled ? Colors.white : color),
        ),
      ),
    );
  }

  Widget _buildEmpty(String title, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 36,
                color: _accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.shellTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
