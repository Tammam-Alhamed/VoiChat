import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/constants.dart';

import '../core/helpers/avatar_helper.dart';
import '../core/helpers/store_helper.dart';
import '../core/helpers/toast_helper.dart';
import '../core/network/service_helper.dart';
import '../core/utils/api_status.dart';
import '../features/settings/recharge/recharge_screen.dart';
import '../app/di/injection_container.dart';
import 'gifts_bottom_sheet.dart';
import 'live_goal.dart';
import 'live_premium.dart';
import 'test_designed_live_room.dart';

import '../features/session/presentation/controllers/session_controller.dart';

/// Opens the Premium join screen when a join response says this live needs
/// the entry gift. Returns true if it did — the caller must not open the
/// live room itself. [replace] swaps the current route (used from inside a
/// live room / the stream-ended screen).
bool openPremiumGateIfRequired(
  dynamic data, {
  required String liveId,
  String? hostId,
  String? hostName,
  String? hostImage,
  String? streamTitle,
  bool replace = false,
}) {
  if (data is! Map || data['requiresPremium'] != true) return false;
  final host = data['hostUser'] is Map ? data['hostUser'] as Map : const {};
  final liveStream = data['liveStream'] is Map
      ? data['liveStream'] as Map
      : const {};

  final screen = PremiumJoinScreen(
    liveId: liveId,
    hostId: (hostId != null && hostId.isNotEmpty)
        ? hostId
        : host['id']?.toString() ?? '',
    hostName: hostName ?? host['name']?.toString() ?? 'Host',
    hostImage: hostImage ?? host['profile_image']?.toString(),
    streamTitle:
        streamTitle ?? liveStream['title']?.toString() ?? 'Live Stream',
    premium:
        LivePremiumInfo.fromJson(data['premium']) ??
        const LivePremiumInfo(isPremium: true, hasAccess: false),
    isVerified: host['is_verified'] == true,
    viewersCount: (data['viewersCount'] as num?)?.toInt(),
    isFollowingHost: data['isFollowingHost'] == true,
  );
  if (replace) {
    Get.off(() => screen);
  } else {
    Get.to(() => screen);
  }
  return true;
}

/// What a viewer sees for a Premium live: the host (blurred photo behind,
/// avatar with a follow "+", name, verified badge), "PREMIUM", the entry
/// gift with its price and "Join now". Paying = the gift is really sent to
/// the host (server: balance check + deduction + gift + access in one step),
/// then the live opens.
class PremiumJoinScreen extends StatefulWidget {
  final String liveId;
  final String hostId;
  final String hostName;
  final String? hostImage;
  final String streamTitle;
  final LivePremiumInfo premium;
  final bool isVerified;
  final int? viewersCount;
  final bool isFollowingHost;

  const PremiumJoinScreen({
    super.key,
    required this.liveId,
    required this.hostId,
    required this.hostName,
    this.hostImage,
    required this.streamTitle,
    required this.premium,
    this.isVerified = false,
    this.viewersCount,
    this.isFollowingHost = false,
  });

  @override
  State<PremiumJoinScreen> createState() => _PremiumJoinScreenState();
}

class _PremiumJoinScreenState extends State<PremiumJoinScreen> {
  late LivePremiumInfo _premium = widget.premium;
  late bool _isVerified = widget.isVerified;
  late int _viewers = widget.viewersCount ?? 0;
  late bool _following = widget.isFollowingHost;
  bool _followBusy = false;
  bool _joining = false;
  bool _insufficient = false;

  @override
  void initState() {
    super.initState();
    _refreshInfo();
  }

  /// Latest gift / viewers / follow state (the host may have changed the
  /// gift meanwhile, and this screen can be opened from several places).
  Future<void> _refreshInfo() async {
    final response = await sl<ServiceHelper>().getHelper(
      target: '/v1/live/${widget.liveId}/premium',
      token: sl<StoreHelper>().getAccessToken(),
    );
    if (response is! Success || !mounted) return;
    try {
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map) return;
      final info = LivePremiumInfo.fromJson(data);
      final host = data['hostUser'];
      setState(() {
        if (info != null) _premium = info;
        if (host is Map) _isVerified = host['is_verified'] == true;
        _viewers = (data['viewersCount'] as num?)?.toInt() ?? _viewers;
        _following = data['isFollowingHost'] == true || _following;
      });
    } catch (_) {}
  }

  Future<void> _follow() async {
    if (_following || _followBusy || widget.hostId.isEmpty) return;
    setState(() => _followBusy = true);
    final response = await sl<ServiceHelper>().postHelper(
      target: '/v1/users/${widget.hostId}/follow',
      token: sl<StoreHelper>().getAccessToken(),
      data: const {},
    );
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (response is Success) _following = true;
    });
    if (response is Failure) {
      final msg = response.errorResponse?.toString() ?? '';
      // Already following → just reflect it.
      if (msg.toLowerCase().contains('already')) {
        setState(() => _following = true);
      } else {
        ToastHelper.showErrorToast(
          message: msg.isEmpty ? 'Failed to follow' : msg,
        );
      }
    }
  }

  Future<void> _joinNow() async {
    if (_joining) return;
    setState(() => _joining = true);

    final response = await sl<ServiceHelper>().postHelper(
      target: '/v1/live/${widget.liveId}/premium/join',
      token: sl<StoreHelper>().getAccessToken(),
      data: const {},
    );
    if (!mounted) return;

    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        final data = body['data'] as Map<String, dynamic>;
        final liveStream = data['liveStream'] as Map<String, dynamic>? ?? {};

        final newBalance = data['newBalance'];
        if (newBalance != null) {
          Get.find<SessionController>().session?.user?.walletBalance =
              newBalance.toString();
        }

        Get.off(
          () => LiveStreamingScreen(
            token: data['token'].toString(),
            roomName: (data['roomName'] ?? liveStream['room_name']).toString(),
            host: Constants.sfu,
            isHost: false,
            liveId: widget.liveId,
            hostId: widget.hostId,
            streamTitle: widget.streamTitle,
            hostName: widget.hostName,
            hostImage: widget.hostImage,
            initialGoal: LiveGoal.fromJson(data['goal']),
            initialGiftsTotal:
                num.tryParse('${liveStream['total_gifts_value']}') ?? 0,
            initialPremium: LivePremiumInfo.fromJson(data['premium']),
          ),
        );
        return;
      } catch (_) {
        ToastHelper.showErrorToast(message: "Couldn't open the live");
      }
    } else if (response is Failure) {
      final message = response.errorResponse?.toString() ?? 'Failed to join';
      if (message.toLowerCase().contains('insufficient')) {
        setState(() => _insufficient = true);
        ToastHelper.showErrorToast(message: 'Not enough coins to join');
      } else {
        ToastHelper.showErrorToast(message: message);
        if (message.toLowerCase().contains('ended')) Get.back();
      }
    }
    if (mounted) setState(() => _joining = false);
  }

  @override
  Widget build(BuildContext context) {
    final gift = _premium.entryGift;
    final price = gift?.price.toInt();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Host photo, heavily blurred, as the whole backdrop.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Image(
                image: AvatarHelper.resolve(widget.hostImage),
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black.withOpacity(0.28)),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 44),
                  _buildAvatar(),
                  const SizedBox(height: 14),
                  _buildName(),
                  const SizedBox(height: 10),
                  const _PremiumWordmark(),
                  const SizedBox(height: 8),
                  const Text(
                    'Join this exclusive moment',
                    style: TextStyle(
                      color: Color(0xFFD9D9DE),
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(flex: 3),
                  _buildGift(gift),
                  const SizedBox(height: 10),
                  if (price != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/icons/sm-coin.png', width: 22),
                        const SizedBox(width: 8),
                        Text(
                          '$price',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  _buildJoinButton(enabled: gift != null),
                  const SizedBox(height: 14),
                  _buildCaption(price),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '+$_viewers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8E8E93), width: 1.5),
              image: DecorationImage(
                image: AvatarHelper.resolve(widget.hostImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Follow "+" (hidden once following).
          if (!_following)
            Positioned(
              right: -4,
              bottom: 2,
              child: GestureDetector(
                onTap: _follow,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3F3F44),
                    shape: BoxShape.circle,
                  ),
                  child: _followBusy
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.hostName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isVerified) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                'assets/moke/verified.png',
                color: const Color(0xFF7247EF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGift(GiftItem? gift) {
    const size = 140.0;
    if (gift == null) {
      return const SizedBox(
        width: size,
        height: size,
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: gift.imageUrl.isEmpty
          ? const Icon(Icons.card_giftcard, color: Colors.white54, size: 80)
          : CachedNetworkImage(
              imageUrl: gift.imageUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(
                Icons.card_giftcard,
                color: Colors.white54,
                size: 80,
              ),
            ),
    );
  }

  Widget _buildJoinButton({required bool enabled}) {
    return GestureDetector(
      onTap: (!enabled || _joining) ? null : _joinNow,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: 260,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F2BFA), Color(0xFFB04BE6)],
            ),
          ),
          child: _joining
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Join now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCaption(int? price) {
    if (_insufficient) {
      // Not in the design's normal state — only after a failed payment.
      return GestureDetector(
        onTap: () async {
          await Get.to(() => const RechargeCenterScreen());
          if (mounted) setState(() => _insufficient = false);
        },
        child: const Text(
          'Not enough coins · Recharge',
          style: TextStyle(
            color: Color(0xFFFFC23A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text(
      price == null ? '' : 'This access costs $price Coins',
      style: const TextStyle(color: Color(0xFFCFCFD4), fontSize: 14),
    );
  }
}

/// "◯-PREMIUM": silver ring + silver lettering.
class _PremiumWordmark extends StatelessWidget {
  const _PremiumWordmark();

  static const _silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2F2F4), Color(0xFF9C9CA3), Color(0xFFE1E1E5)],
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: _silver,
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF55555C),
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => _silver.createShader(bounds),
          child: const Text(
            '-PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}
