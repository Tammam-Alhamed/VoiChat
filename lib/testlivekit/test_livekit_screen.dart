import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/di/injection_container.dart';
import '../core/network/service_helper.dart';
import '../core/helpers/store_helper.dart';
import '../core/helpers/toast_helper.dart';
import '../core/utils/api_status.dart';
import 'test_designed_live_room.dart';

class TestLiveKitScreen extends StatefulWidget {
  const TestLiveKitScreen({super.key});

  @override
  State<TestLiveKitScreen> createState() => _TestLiveKitScreenState();
}

class _TestLiveKitScreenState extends State<TestLiveKitScreen> {
  final _serviceHelper = sl<ServiceHelper>();
  final _storeHelper = sl<StoreHelper>();

  final _titleController = TextEditingController(
    text: "My Awesome Live Stream",
  );
  final _customUrlController = TextEditingController();

  List<dynamic> _activeStreams = [];
  bool _isLoadingStreams = false;
  bool _isStartingLive = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchActiveStreams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveStreams() async {
    setState(() {
      _isLoadingStreams = true;
      _errorMsg = null;
    });

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/active?page=1&limit=50',
      token: token,
    );

    setState(() {
      _isLoadingStreams = false;
    });

    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final rawData = body['data'];
          if (rawData is List) {
            setState(() {
              _activeStreams = rawData;
            });
          } else if (rawData is Map && rawData['data'] is List) {
            setState(() {
              _activeStreams = rawData['data'];
            });
          }
        }
      } catch (e) {
        setState(() {
          _errorMsg = "Failed to parse active streams.";
        });
      }
    } else if (response is Failure) {
      setState(() {
        _errorMsg = response.errorResponse.toString();
      });
    }
  }

  Future<void> _startLiveStream() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ToastHelper.showErrorToast(message: "Please enter a stream title");
      return;
    }

    setState(() {
      _isStartingLive = true;
      _errorMsg = null;
    });

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.postHelper(
      target: '/v1/live/start',
      token: token,
      data: {'title': title},
    );

    setState(() {
      _isStartingLive = false;
    });

    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final liveStream = data['liveStream'];
          final tokenVal = data['token'];
          final roomName = data['roomName'] ?? liveStream['room_name'];
          final hostVal = _customUrlController.text.trim().isNotEmpty
              ? _customUrlController.text.trim()
              : (data['host'] ?? "wss://sfu-st.voichat.live");

          Get.to(
            () => LiveStreamingScreen(
              token: tokenVal,
              roomName: roomName,
              host: hostVal,
              isHost: true,
              liveId: liveStream['id'].toString(),
              streamTitle: liveStream['title'] ?? title,
              hostName: 'You',
            ),
          );
        } else {
          setState(() {
            _errorMsg = body['message'] ?? "Unknown start live error.";
          });
        }
      } catch (e) {
        setState(() {
          _errorMsg = "Failed to parse start live response.";
        });
      }
    } else if (response is Failure) {
      setState(() {
        _errorMsg = response.errorResponse.toString();
      });
    }
  }

  Future<void> _joinLiveStream(dynamic stream) async {
    final liveId = stream['id'].toString();
    final streamTitle = stream['title'] ?? "Live Stream";

    setState(() {
      _isLoadingStreams = true;
    });

    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.postHelper(
      target: '/v1/live/$liveId/join',
      data: {"hi": "pk"},
      token: token,
    );

    setState(() {
      _isLoadingStreams = false;
    });

    if (response is Success) {
      try {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final liveStream = data['liveStream'];
          final tokenVal = data['token'];
          final roomName = liveStream['room_name'];
          final hostVal = _customUrlController.text.trim().isNotEmpty
              ? _customUrlController.text.trim()
              : (data['host'] ?? "wss://sfu-st.voichat.live");

          final hostUser = stream['User'] ?? {};
          Get.to(
            () => LiveStreamingScreen(
              token: tokenVal,
              roomName: roomName,
              host: hostVal,
              isHost: false,
              liveId: liveId,
              streamTitle: streamTitle,
              hostName: hostUser['name'] ?? 'Host',
              hostImage: hostUser['profile_image'],
            ),
          );
        } else {
          ToastHelper.showErrorToast(
            message: body['message'] ?? "Failed to join live room",
          );
        }
      } catch (e) {
        ToastHelper.showErrorToast(message: "Failed to parse join response");
      }
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "LiveKit Dev Sandbox",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchActiveStreams,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Connection settings
              _buildSectionTitle("1. LiveKit Host Override (Optional)"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _customUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "wss://sfu-st.voichat.live (default)",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    icon: Icon(Icons.link, color: Colors.deepPurpleAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Start Live Section
              _buildSectionTitle("2. Broadcast (Start a Live Stream)"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1B4D), Color(0xFF1F1F1F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Stream Title",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isStartingLive ? null : _startLiveStream,
                      icon: _isStartingLive
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sensors, color: Colors.white),
                      label: Text(
                        _isStartingLive ? "Starting Room..." : "GO LIVE NOW",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B3EE8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Active streams Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(
                    "3. Active Streams (${_activeStreams.length})",
                  ),
                  if (_isLoadingStreams)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              if (_activeStreams.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeStreams.length,
                  itemBuilder: (context, index) {
                    final stream = _activeStreams[index];
                    return _buildStreamCard(stream);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.tv_off, size: 48, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            "No active streams found",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchActiveStreams,
            icon: const Icon(Icons.refresh, color: Colors.deepPurpleAccent),
            label: const Text(
              "Refresh List",
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamCard(dynamic stream) {
    final user = stream['User'] ?? {};
    final title = stream['title'] ?? "No Title";
    final viewersCount = stream['viewers_count'] ?? 0;
    final hostName = user['name'] ?? "Unknown Host";
    final isVerified = user['is_verified'] == true;

    return InkWell(
      onLongPress: () {
        deleteLiveStream(stream);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          onLongPress: () {
            deleteLiveStream(stream);
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.deepPurpleAccent),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 12,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      viewersCount.toString(),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Text(
                  "Host: $hostName",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: Colors.blueAccent,
                  ),
                ],
              ],
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () => _joinLiveStream(stream),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text("JOIN"),
          ),
        ),
      ),
    );
  }

  void deleteLiveStream(dynamic stream) async {
    setState(() {
      _isLoadingStreams = true;
    });
    final token = _storeHelper.getAccessToken();

    await _serviceHelper.postHelper(
      target: '/v1/live/end',
      token: token,
      data: {"rem": "yes"},
    );

    setState(() {
      _isLoadingStreams = false;
    });
  }
}
