import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:shoeebapk/core/extentions.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/di/injection_container.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/helpers/toast_helper.dart';
import '../../core/helpers/avatar_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/helpers/store_helper.dart';
import '../../core/utils/api_status.dart';
import '../calls/state/calls_provider.dart';
import 'viewmodel/chat_viewmodel.dart';
import '../home/tabs/messages/viewmodel/messages_tab_viewmodel.dart';
import '../home/tabs/messages/models/conversation_model.dart';
import 'widgets/audio_player_widget.dart';
import 'widgets/chat_video_bubble.dart';
import '../../testlivekit/gifts_bottom_sheet.dart';

class ChatScreen extends StatefulWidget {
  /// The ID of the other user (used to send messages via REST).
  final String receiverId;
  final String userName;
  final String? userAvatar;

  /// True when this is the app-wide Support conversation (see
  /// SupportChatScreen, which reuses this same chat pipeline). Support
  /// should stay text + photos only — no gifts (there's no one on the
  /// other end to receive them meaningfully), no voice notes, no video.
  final bool isSupportChat;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.userName,
    this.userAvatar,
    this.isSupportChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatViewModel _chatViewModel;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isRecording = false;

  // The message currently long-pressed (shows the WhatsApp-style top action
  // bar with Reply/Forward/Copy/Delete instead of the normal app bar).
  MessageModel? _selectedMessage;

  // The message being replied to, shown as a quoted preview above the
  // input box until sent or dismissed.
  MessageModel? _replyingTo;
  final FocusNode _inputFocusNode = FocusNode();

  // Tracks the in-flight start() call so a near-instant stop (e.g. the
  // 5-minute auto-stop firing right as recording begins) can wait for it
  // to actually finish (success or failure) before trying to stop — this
  // is the classic "recording sometimes doesn't work" race.
  Future<void>? _recorderStarting;
  String? _pendingRecordingPath;

  // Live "0:07" counter shown while actively recording.
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  static const _maxRecordingDuration = Duration(minutes: 5);

  // Instagram-style preview: once recording stops, the file waits here
  // until the user explicitly hits send (or discards it) — nothing is
  // uploaded until then.
  String? _pendingVoicePath;
  Duration _pendingVoiceDuration = Duration.zero;
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  Duration _previewPosition = Duration.zero;
  List<double> _waveformHeights = const [];
  StreamSubscription<void>? _previewCompleteSub;
  StreamSubscription<Duration>? _previewPositionSub;
  StreamSubscription<PlayerState>? _previewStateSub;

  @override
  void initState() {
    super.initState();
    _chatViewModel = sl<ChatViewModel>();

    // Look up an existing conversation (or message request) with this user
    // in MessagesTabViewModel. If none is loaded locally, ChatViewModel asks
    // the server.
    final messagesViewModel = sl<MessagesTabViewModel>();
    final existing = messagesViewModel.conversationWith(widget.receiverId);

    _chatViewModel.onError = (message) {
      if (mounted) ToastHelper.showErrorToast(message: message);
    };
    _chatViewModel.attachMessagesTab(messagesViewModel);
    _chatViewModel.initChat(
      widget.receiverId,
      existing?.id,
      status: existing?.status,
      requestedBy: existing?.requestedBy,
    );

    _previewStateSub = _previewPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPreviewPlaying = state == PlayerState.playing);
      }
    });
    _previewPositionSub = _previewPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
    _previewCompleteSub = _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = false;
          _previewPosition = Duration.zero;
        });
      }
    });

    _messageController.addListener(() {
      setState(() {}); // to toggle send/mic icon

      // Handle typing emission
      if (_messageController.text.isNotEmpty && !_isTyping) {
        _isTyping = true;
        _chatViewModel.sendTyping(true);
      }

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          _chatViewModel.sendTyping(false);
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    if (_isTyping) _chatViewModel.sendTyping(false);
    _messageController.dispose();
    _inputFocusNode.dispose();
    _chatViewModel.dispose();
    _audioRecorder.dispose();
    _previewStateSub?.cancel();
    _previewPositionSub?.cancel();
    _previewCompleteSub?.cancel();
    _previewPlayer.dispose();
    // Don't leave an unsent recording clogging up device storage.
    if (_pendingVoicePath != null) {
      try {
        File(_pendingVoicePath!).deleteSync();
      } catch (_) {
        // best-effort cleanup
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatViewModel,
      child: Scaffold(
        backgroundColor: context.shellBackground,
        body: SafeArea(
          child: Column(
            children: [
              // 1. App Bar — swaps to the selection action bar while a
              // message is long-pressed.
              _selectedMessage != null
                  ? _buildSelectionAppBar(context)
                  : _buildCustomAppBar(context),

              Container(height: 1, color: const Color(0xFFF5F5F5)),

              // 2. Messages List
              Expanded(
                child: Consumer<ChatViewModel>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.messages.isEmpty) {
                      final startsRequest =
                          provider.isNewChat && !widget.isSupportChat;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            startsRequest
                                ? "Say hi! 👋\nYour first message will be sent as a message request."
                                : "Say hi! 👋",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      reverse: true, // Show newest at the bottom
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        final isMe = msg.senderId != widget.receiverId;
                        return _buildMessageBubble(
                          msg: msg,
                          time: timeago.format(
                            msg.createdAt,
                            locale: 'en_short',
                          ),
                          isMe: isMe,
                          mediaProgress: provider.progressFor(msg.id),
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. Input Area
              _buildMessageInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // الدوال المساعدة لبناء الواجهة بنظافة
  // ==========================================

  // بناء الشريط العلوي (صورة المستخدم، اسمه، وحالته)
  Widget _buildCustomAppBar(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, provider, _) {
        // Once the first fetchMessages() resolves, the server-resolved
        // name/photo (live, frozen snapshot, or default avatar — depending
        // on blockStatus) takes over from the constructor params used for
        // the very first frame.
        final displayName = provider.otherUserName ?? widget.userName;
        final displayImage = provider.otherUserImage ?? widget.userAvatar;
        final isBlocked = provider.isBlocked;

        final avatarProvider = AvatarHelper.resolve(displayImage);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: context.shellTextPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: avatarProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Typing/presence status is hidden entirely once either
                    // side has blocked the other — nothing to show either
                    // way (no message box, no live presence to report).
                    if (!isBlocked)
                      Consumer<MessagesTabViewModel>(
                        builder: (context, msgViewModel, _) {
                          final isTyping =
                              _chatViewModel.conversationId != null &&
                              msgViewModel.isTyping(
                                _chatViewModel.conversationId!,
                              );

                          if (isTyping) {
                            return const Text(
                              'Typing...',
                              style: TextStyle(
                                color: Color(0xFF6044FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }

                          return const Text(
                            'Active now',
                            style: TextStyle(
                              color: Color(0xFF7A7A7A),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              // Voice/video call ("1:1") entry point disappears the moment
              // either side has blocked the other.
              if (!isBlocked) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    context.read<CallsProvider>().initiateCall(
                      receiverId: widget.receiverId
                          .toString(), // ID of the user you want to call
                      receiverName: displayName,
                      receiverImage: displayImage,
                      callType: 'video', // 'audio' or 'video'
                    );
                  },
                  child: SvgPicture.asset("assets/icons/start_video_call.svg"),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.more_vert, color: Colors.black),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Message',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this message for everyone?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _chatViewModel.deleteMessage(id);
                _clearSelection();
              },
              child: const Text('Delete').white,
            ),
          ],
        );
      },
    );
  }

  void _clearSelection() {
    if (_selectedMessage != null) setState(() => _selectedMessage = null);
  }

  // A short, human label for a message — used both in the reply preview
  // above the input and in the quoted block rendered inside a bubble.
  String _previewLabel(String messageType, String? content) {
    switch (messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      default:
        return content ?? '';
    }
  }

  // Top action bar shown in place of the normal app bar while a message is
  // selected (long-pressed) — mirrors the WhatsApp/Telegram pattern instead
  // of popping a delete confirmation straight away.
  Widget _buildSelectionAppBar(BuildContext context) {
    final selected = _selectedMessage!;
    final isMe = selected.senderId != widget.receiverId;
    final isTemp = selected.id.startsWith('temp_');
    final isText = selected.messageType == 'text';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(Icons.close, color: context.shellTextPrimary),
          ),
          const Spacer(),
          if (!isTemp)
            IconButton(
              tooltip: 'Reply',
              onPressed: () {
                setState(() {
                  _replyingTo = selected;
                  _selectedMessage = null;
                });
                _inputFocusNode.requestFocus();
              },
              icon: Icon(Icons.reply, color: context.shellTextPrimary),
            ),
          if (!isTemp)
            IconButton(
              tooltip: 'Forward',
              onPressed: () => _showForwardSheet(selected),
              icon: Icon(Icons.forward, color: context.shellTextPrimary),
            ),
          if (isText)
            IconButton(
              tooltip: 'Copy',
              onPressed: () => _copyMessage(selected),
              icon: Icon(Icons.copy, color: context.shellTextPrimary),
            ),
          if (isMe && !isTemp)
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _showDeleteDialog(selected.id),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  void _copyMessage(MessageModel msg) {
    Clipboard.setData(ClipboardData(text: msg.content ?? ''));
    _clearSelection();
    ToastHelper.showSuccessToast(message: 'Copied to clipboard');
  }

  // Bottom sheet listing the user's conversations so they can pick who to
  // forward this message to. Reuses MessagesTabViewModel's already-loaded
  // conversation list instead of a fresh fetch.
  void _showForwardSheet(MessageModel message) {
    final messagesViewModel = sl<MessagesTabViewModel>();
    final conversations = messagesViewModel.conversations;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Forward to...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Flexible(
                  child: conversations.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No conversations yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            final avatarProvider = AvatarHelper.resolve(
                              conv.otherUser.profileImage,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: avatarProvider,
                              ),
                              title: Text(conv.otherUser.name),
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                final ok = await _chatViewModel.forwardMessage(
                                  message,
                                  conv.otherUser.id,
                                );
                                if (!mounted) return;
                                if (ok) {
                                  ToastHelper.showSuccessToast(
                                    message:
                                        'Forwarded to ${conv.otherUser.name}',
                                  );
                                } else {
                                  ToastHelper.showErrorToast(
                                    message: 'Failed to forward message',
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _clearSelection();
  }

  // The small quoted block rendered at the top of a bubble when the message
  // is a reply — tapping content here isn't wired to jump-to-message since
  // there's no message index lookup yet, just a static WhatsApp-style quote.
  Widget _buildQuotedReply(MessageModel msg, bool isMe) {
    final quotedIsMe = msg.replyToSenderId != widget.receiverId;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : const Color(0xFF6044FF),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quotedIsMe ? 'You' : widget.userName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white : const Color(0xFF6044FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _previewLabel(msg.replyToType ?? 'text', msg.replyToContent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // بناء فقاعة المحادثة الذكية (تأخذ النص والوقت وتحدد مكانها بناءً على isMe)
  Widget _buildMessageBubble({
    required MessageModel msg,
    required String time,
    required bool isMe,
    MediaUploadProgress? mediaProgress,
  }) {
    final id = msg.id;
    final message = msg.content ?? '';
    final messageType = msg.messageType;
    final mediaUrl = msg.mediaUrl;
    final thumbnailUrl = msg.thumbnailUrl;
    final status = msg.status;
    final isRead = msg.isRead;
    final isTemp = id.startsWith('temp_');
    final isSelected = _selectedMessage?.id == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: status == MessageStatus.sending ? 0.7 : 1.0,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: isTemp
                ? null
                : () => setState(() => _selectedMessage = msg),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: messageType == 'text' ? 12 : 6,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isMe
                          ? const Color(0xFF6044FF).withOpacity(0.6)
                          : const Color(0xFFD8D8D8))
                    : (isMe
                          ? const Color(0xFF6044FF)
                          : const Color(0xFFEDEDED)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.replyToId != null) _buildQuotedReply(msg, isMe),
                  if (messageType == 'image' && mediaUrl != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!isTemp) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  barrierColor: Colors.black,
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                        return Scaffold(
                                          backgroundColor: Colors.transparent,
                                          body: Stack(
                                            children: [
                                              PhotoView(
                                                imageProvider:
                                                    mediaUrl.startsWith('http')
                                                    ? CachedNetworkImageProvider(
                                                        mediaUrl,
                                                      )
                                                    : FileImage(File(mediaUrl))
                                                          as ImageProvider,
                                                minScale: PhotoViewComputedScale
                                                    .contained,
                                                maxScale:
                                                    PhotoViewComputedScale
                                                        .covered *
                                                    3,
                                                heroAttributes:
                                                    PhotoViewHeroAttributes(
                                                      tag: id,
                                                    ),
                                                backgroundDecoration:
                                                    const BoxDecoration(
                                                      color: Colors.black,
                                                    ),
                                              ),
                                              Positioned(
                                                top:
                                                    MediaQuery.of(
                                                      context,
                                                    ).padding.top +
                                                    16,
                                                left: 16,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.4),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 2.0,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .arrow_back_ios_new_rounded,
                                                        color: Colors.white,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: id,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: mediaUrl.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: mediaUrl,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Image.file(
                                      File(mediaUrl),
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (isTemp)
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    )
                  else if (messageType == 'video' && mediaUrl != null)
                    ChatVideoBubble(
                      videoUrl: mediaUrl,
                      thumbnailUrl: thumbnailUrl,
                      isTemp: isTemp,
                      progress: mediaProgress,
                    )
                  else if (messageType == 'audio' && mediaUrl != null)
                    AudioPlayerWidget(
                      key: ValueKey(id),
                      url: mediaUrl,
                      isMe: isMe,
                      isTemp: isTemp,
                    )
                  else
                    Text(
                      message,
                      // Force RTL: without this, Flutter's bidi algorithm
                      // picks direction from the first strong character, so
                      // a message starting with an English word/number
                      // flips the whole line to LTR even inside an Arabic
                      // sentence. Forcing RTL keeps it consistent.
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        if (status == MessageStatus.sending)
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.white70,
                          )
                        else if (status == MessageStatus.failed)
                          const Icon(
                            Icons.error_outline,
                            size: 12,
                            color: Colors.redAccent,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2),
                            child: Icon(
                              Icons.done_all,
                              // Read receipt: turns blue once the other
                              // person has actually read the message
                              // (isRead), otherwise keeps the neutral
                              // "delivered" color.
                              color: isRead
                                  ? const Color(0xFF34B7F1)
                                  : Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء حقل إدخال النص في الأسفل
  Widget _buildMessageInputArea() {
    return Consumer<ChatViewModel>(
      builder: (context, provider, _) {
        if (provider.blockStatus == 'blockedByMe') {
          return _buildBlockedByMeBar(provider);
        }
        if (provider.blockStatus == 'blockedMe') {
          return _buildBlockedMeBar();
        }

        return Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message requests: the receiver sees Accept / Delete (replying
              // also accepts); the sender sees that it's still pending.
              if (provider.isIncomingRequest)
                _buildIncomingRequestBar(provider)
              else if (provider.isOutgoingRequest)
                _buildOutgoingRequestNote(),
              if (_replyingTo != null) _buildReplyPreviewBar(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _buildMessageInputRow(),
              ),
            ],
          ),
        );
      },
    );
  }

  // While my request is pending (or before the first message creates it)
  // only text can be sent — the server enforces the same rule.
  bool get _textOnlyComposer =>
      !widget.isSupportChat &&
      (_chatViewModel.isOutgoingRequest ||
          _chatViewModel.conversationId == null);

  // Shown above the (unchanged) message box when someone I don't chat with
  // yet sent me a request: Block / Delete — or just reply, which accepts it
  // and moves the chat to my normal list.
  Widget _buildIncomingRequestBar(ChatViewModel provider) {
    final name = provider.otherUserName ?? widget.userName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xFF7A7A7A),
                fontSize: 13.5,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'When you reply, '),
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' will be able to contact you and see your status.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _requestActionButton('Block', _confirmBlockRequester),
              const SizedBox(width: 16),
              _requestActionButton('Delete', _confirmDeclineRequest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: 118,
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E2E2)),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _confirmBlockRequester() async {
    final name = _chatViewModel.otherUserName ?? widget.userName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Block',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$name won\'t be able to message or call you, and this request will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _chatViewModel.blockAndRemoveRequest();
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccessToast(message: '$name blocked');
      Navigator.pop(context);
    }
  }

  // Shown to the sender while their request hasn't been accepted yet.
  Widget _buildOutgoingRequestNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF5F2FF),
      child: const Row(
        children: [
          Icon(Icons.schedule, size: 16, color: Color(0xFF6044FF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Message request sent. You can send up to 5 text messages until they accept.',
              style: TextStyle(color: Color(0xFF555555), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeclineRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This request and its messages will be deleted. They won\'t be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await _chatViewModel.removeRequest();
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  // Shown in place of the message box once I've blocked this person: the
  // only two things left to do with this conversation.
  Widget _buildBlockedByMeBar(ChatViewModel provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final ok = await provider.unblockUser();
                if (!mounted) return;
                if (ok) {
                  ToastHelper.showSuccessToast(message: 'User unblocked');
                  provider.fetchMessages();
                } else {
                  ToastHelper.showErrorToast(message: 'Failed to unblock user');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6044FF),
                side: const BorderSide(color: Color(0xFF6044FF)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _confirmDeleteChat,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Delete Chat',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shown in place of the message box when the other person has blocked
  // me — there's nothing I can do here except leave, so no actions at all.
  Widget _buildBlockedMeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: const Center(
        child: Text(
          'You cannot reply to this conversation',
          style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will remove the conversation from your list. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _chatViewModel.deleteConversation();
    if (!mounted) return;

    if (ok) {
      final convId = _chatViewModel.conversationId;
      if (convId != null) {
        sl<MessagesTabViewModel>().deleteConversations({convId});
      }
      Navigator.pop(context);
    } else {
      ToastHelper.showErrorToast(message: 'Failed to delete chat');
    }
  }

  // The WhatsApp-style "replying to ..." strip shown above the text field,
  // with a snippet of the quoted message and a close button to cancel.
  Widget _buildReplyPreviewBar() {
    final replying = _replyingTo!;
    final isMe = replying.senderId != widget.receiverId;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: const Color(0xFF6044FF), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : widget.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6044FF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewLabel(replying.messageType, replying.content),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingTo = null),
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputRow() {
    if (_isRecording) return _buildRecordingRow();
    if (_pendingVoicePath != null) return _buildVoicePreviewRow();
    return _buildTextComposerRow();
  }

  // Normal state: text field + mic/attach/camera inside the gray pill,
  // and a trailing round button that's 🎁 when empty or ➤ once typing.
  Widget _buildTextComposerRow() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _inputFocusNode,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Color(0xFF6E6D6D),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Support conversations stay text + photos only — no voice
                // notes, no gifts (see widget.isSupportChat docs).
                if (!widget.isSupportChat && !_textOnlyComposer) ...[
                  InkWell(
                    onTap: _beginRecording,
                    child: const Icon(
                      Icons.mic_none,
                      color: Color(0xFF6E6D6D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (!_textOnlyComposer) ...[
                  InkWell(
                    onTap: () => _showAttachSheet(ImageSource.gallery),
                    child: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF6E6D6D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showAttachSheet(ImageSource.camera),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF6E6D6D),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // زر الإرسال / الهدية — support conversations never offer the gift
        // action (no one to meaningfully receive it there); the button just
        // stays a disabled send icon until there's text to send.
        GestureDetector(
          onTap: () {
            if (hasText) {
              _chatViewModel.sendMessage(
                _messageController.text.trim(),
                replyTo: _replyingTo,
              );
              _messageController.clear();
              setState(() => _replyingTo = null);
            } else if (!widget.isSupportChat && !_textOnlyComposer) {
              _openGiftSheet();
            }
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: hasText || (!widget.isSupportChat && !_textOnlyComposer)
                  ? const Color(0xFF6044FF)
                  : const Color(0xFFBDBDBD),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: hasText
                  ? const Icon(Icons.send, color: Colors.white, size: 24)
                  : widget.isSupportChat || _textOnlyComposer
                  ? const Icon(Icons.send, color: Colors.white, size: 24)
                  : const Text('🎁', style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ],
    );
  }

  // Active recording: red dot + live duration inside the gray pill, a
  // cancel (trash) icon to discard, and a stop button to move to preview.
  Widget _buildRecordingRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordingElapsed),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _cancelRecording,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF6E6D6D),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _stopRecordingToPreview,
          child: Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFF6044FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Instagram-style preview: play/pause + waveform + duration inside the
  // gray pill, a trash icon to discard/re-record, and an explicit send.
  Widget _buildVoicePreviewRow() {
    final total = _pendingVoiceDuration;
    final double progress = total.inMilliseconds > 0
        ? (_previewPosition.inMilliseconds / total.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _togglePreviewPlayback,
                  child: Icon(
                    _isPreviewPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: const Color(0xFF6044FF),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoiceWaveform(
                    heights: _waveformHeights,
                    progress: progress,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_isPreviewPlaying ? _previewPosition : total),
                  style: const TextStyle(
                    color: Color(0xFF6E6D6D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _discardVoicePreview,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.delete_outline,
              color: Color(0xFF6E6D6D),
              size: 24,
            ),
          ),
        ),
        GestureDetector(
          onTap: _sendVoiceMessage,
          child: Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFF6044FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Fired by tapping the inline mic icon (a simple tap, not a hold) — kicks
  /// off recording and a live duration counter. Recording only actually
  /// gets sent once the user separately confirms via the preview's send
  /// button; a tap here never uploads anything by itself.
  Future<void> _beginRecording() async {
    setState(() {
      _isRecording = true;
      _recordingElapsed = Duration.zero;
    });
    _recorderStarting = _startRecording();
    await _recorderStarting;

    if (_pendingRecordingPath == null) {
      // start() failed (e.g. permission denied) — _startRecording already
      // reset _isRecording.
      return;
    }

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingElapsed += const Duration(milliseconds: 200);
      });
      if (_recordingElapsed >= _maxRecordingDuration) {
        _stopRecordingToPreview();
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) setState(() => _isRecording = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        // AAC-LC keeps voice notes small and fast to send — a WAV of the
        // same length would be 10-20x larger for no audible benefit.
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: path,
      );
      _pendingRecordingPath = path;
    } catch (e) {
      if (mounted) setState(() => _isRecording = false);
      debugPrint('Error starting recorder: $e');
    }
  }

  // Stops the recorder and moves into the preview state — nothing is sent
  // yet, the user still has to explicitly hit send from the preview row.
  Future<void> _stopRecordingToPreview() async {
    if (!_isRecording) return;
    await _recorderStarting;
    _recordingTimer?.cancel();

    final elapsed = _recordingElapsed;
    final path = _pendingRecordingPath;
    _pendingRecordingPath = null;

    String? stoppedPath;
    try {
      stoppedPath = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }
    stoppedPath ??= path;

    if (!mounted) return;

    if (stoppedPath == null) {
      setState(() => _isRecording = false);
      return;
    }

    setState(() {
      _isRecording = false;
      _pendingVoicePath = stoppedPath;
      _pendingVoiceDuration = elapsed;
      _previewPosition = Duration.zero;
      _waveformHeights = _generateWaveform(elapsed);
    });
  }

  // Discards the in-progress recording entirely and returns to the normal
  // text/gift composer — this is the "cancel" the spec calls for.
  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorderStarting;
    final path = _pendingRecordingPath;
    _pendingRecordingPath = null;

    try {
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        // best-effort cleanup
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingElapsed = Duration.zero;
      });
    }
  }

  // Deletes the previewed-but-unsent recording (the 🗑️ in the preview row)
  // so the user can re-record from scratch.
  Future<void> _discardVoicePreview() async {
    await _previewPlayer.stop();
    final path = _pendingVoicePath;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        // best-effort cleanup
      }
    }
    if (mounted) {
      setState(() {
        _pendingVoicePath = null;
        _pendingVoiceDuration = Duration.zero;
        _previewPosition = Duration.zero;
        _isPreviewPlaying = false;
        _waveformHeights = const [];
      });
    }
  }

  Future<void> _togglePreviewPlayback() async {
    final path = _pendingVoicePath;
    if (path == null) return;
    if (_isPreviewPlaying) {
      await _previewPlayer.pause();
    } else {
      await _previewPlayer.play(DeviceFileSource(path));
    }
  }

  // Only actually uploads the recording — everything up to this point
  // (tap, cancel, re-record) never touches the network.
  Future<void> _sendVoiceMessage() async {
    final path = _pendingVoicePath;
    if (path == null) return;

    await _previewPlayer.stop();
    _chatViewModel.sendMediaMessage(path, 'audio');

    if (mounted) {
      setState(() {
        _pendingVoicePath = null;
        _pendingVoiceDuration = Duration.zero;
        _previewPosition = Duration.zero;
        _isPreviewPlaying = false;
        _waveformHeights = const [];
      });
    }
  }

  // Static-but-stable "fake" waveform (no real amplitude analysis is
  // wired up), seeded by the recording length so it doesn't reshuffle on
  // every rebuild — good enough for the Instagram-style preview look.
  List<double> _generateWaveform(Duration duration) {
    final barCount = 28;
    final random = Random(
      duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds,
    );
    return List.generate(barCount, (_) => 0.25 + random.nextDouble() * 0.75);
  }

  /// Opens the real gift catalog (same one used in live rooms) and, once a
  /// gift is picked, actually spends the coins via the wallet endpoint —
  /// context 'profile' since this is a direct 1:1 chat gift, not a live one.
  Future<void> _openGiftSheet() async {
    final gift = await showGiftBottomSheet(context);
    if (gift == null || !mounted) return;

    final serviceHelper = sl<ServiceHelper>();
    final token = sl<StoreHelper>().getAccessToken();
    final response = await serviceHelper.postHelper(
      target: '/v1/wallet/gifts/send',
      token: token,
      data: {
        'receiverId': widget.receiverId,
        'giftId': gift.id,
        'context': 'profile',
      },
    );

    if (!mounted) return;

    if (response is Failure) {
      final message = response.errorResponse?.toString().isNotEmpty == true
          ? response.errorResponse.toString()
          : 'Failed to send gift';
      ToastHelper.showErrorToast(message: message);
      return;
    }

    ToastHelper.showSuccessToast(
      message: '🎁 Gift sent to ${widget.userName}!',
    );
  }

  /// Shows a small "Photo / Video" chooser, then routes to the matching
  /// picker for the given [source] (gallery or camera). Support
  /// conversations skip the chooser entirely and go straight to the photo
  /// picker — text + photos only, no video there.
  Future<void> _showAttachSheet(ImageSource source) async {
    if (widget.isSupportChat) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        _chatViewModel.sendMediaMessage(image.path, 'image');
      }
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_outlined,
                color: Color(0xFF6044FF),
              ),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(
                Icons.videocam_outlined,
                color: Color(0xFF6044FF),
              ),
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == 'photo') {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        _chatViewModel.sendMediaMessage(image.path, 'image');
      }
    } else if (choice == 'video') {
      // maxDuration is a hard limit for camera recording; gallery picks
      // still need the 5-minute check done in ChatViewModel.sendVideoMessage
      // since users can select an existing, longer clip there.
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        _chatViewModel.sendVideoMessage(video.path);
      }
    }
  }
}

/// A row of thin bars standing in for a real audio waveform (no amplitude
/// analysis is wired up to the recorder), with bars up to [progress]
/// highlighted in the accent color to show playback position — same idea
/// as Instagram's voice-note preview bar.
class _VoiceWaveform extends StatelessWidget {
  final List<double> heights;
  final double progress;

  const _VoiceWaveform({required this.heights, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (heights.isEmpty) return const SizedBox(height: 24);

    final playedCount = (heights.length * progress).round();

    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (index) {
          final played = index < playedCount;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 24 * heights[index],
              decoration: BoxDecoration(
                color: played
                    ? const Color(0xFF6044FF)
                    : const Color(0xFFD8D5F5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
