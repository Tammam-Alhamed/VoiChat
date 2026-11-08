import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/utils/api_status.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../app/di/injection_container.dart';
import '../chat/chat_screen.dart';

/// "Support Chat" used to be a hardcoded, fake conversation that only ever
/// appended locally. There's no separate ticketing system in this app, so
/// the real fix is to reuse the exact same 1:1 chat pipeline every other
/// conversation uses, pointed at a single app-wide Support account
/// (found-or-created lazily by the backend on first use). That gives
/// support chat real persistence, real delivery, and every existing chat
/// feature (images, voice notes, replies) for free.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool _isLoading = true;
  bool _hasError = false;
  String? _supportId;
  String _supportName = 'Support';
  String? _supportAvatar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/users/support-contact',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null && data['id'] != null) {
          _supportId = data['id'].toString();
          _supportName = data['name']?.toString() ?? 'Support';
          _supportAvatar = data['profile_image']?.toString();
          setState(() => _isLoading = false);
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.shellBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasError || _supportId == null) {
      return Scaffold(
        backgroundColor: context.shellBackground,
        body: SafeArea(child: AppStateView.error(onRetry: _load)),
      );
    }

    return ChatScreen(
      receiverId: _supportId!,
      userName: _supportName,
      userAvatar: _supportAvatar,
      isSupportChat: true,
    );
  }
}
