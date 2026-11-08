import 'package:get/get.dart';

import '../../../../core/constants.dart';
import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';
import '../../../../core/helpers/toast_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../testlivekit/go_live_setup_screen.dart';
import '../../../../testlivekit/live_filters.dart';
import '../../../../testlivekit/live_goal.dart';
import '../../../../testlivekit/live_premium.dart';
import '../../../../testlivekit/premium_join_screen.dart';
import '../../../../testlivekit/test_designed_live_room.dart';
import '../../../session/presentation/controllers/session_controller.dart';
import '../../domain/entities/live_session_access.dart';
import '../../domain/usecases/end_live.dart';
import '../../domain/usecases/get_active_live.dart';
import '../../domain/usecases/join_live.dart';
import '../../domain/usecases/start_live.dart';
import '../widgets/resume_live_dialog.dart';

/// Every way into a live room: joining a user's broadcast, starting a new
/// one from the Go Live screen, and resuming the host's own session after
/// the app was closed mid-broadcast.
class LiveEntryController extends GetxController {
  final JoinLive _joinLive;
  final StartLive _startLive;
  final GetActiveLive _getActiveLive;
  final EndLive _endLive;

  LiveEntryController({
    required JoinLive joinLive,
    required StartLive startLive,
    required GetActiveLive getActiveLive,
    required EndLive endLive,
  }) : _joinLive = joinLive,
       _startLive = startLive,
       _getActiveLive = getActiveLive,
       _endLive = endLive;

  static const String _sfuHost = 'wss://sfu-st.voichat.live';

  bool _checkingResumable = false;

  /// Opens [user]'s broadcast [stream] as a viewer. Premium rooms the user
  /// hasn't paid for open the "Join now" screen instead.
  Future<void> joinLiveStream(LiveStream stream, ClientUser user) async {
    final liveId = stream.id.toString();
    final streamTitle = stream.title;

    final result = await _joinLive(liveId);
    switch (result) {
      case Err(:final failure):
        ToastHelper.showErrorToast(message: failure.message);
      case Ok(data: final access):
        try {
          if (openPremiumGateIfRequired(
            access.raw,
            liveId: liveId,
            hostId: user.id,
            hostName: user.name,
            hostImage: user.profileImage,
            streamTitle: streamTitle,
          )) {
            return;
          }
          final liveStream = access.raw['liveStream'];
          Get.to(
            () => LiveStreamingScreen(
              token: access.token,
              roomName: liveStream['room_name'],
              host: Constants.sfu,
              isHost: false,
              liveId: liveId,
              hostId: user.id,
              streamTitle: streamTitle,
              hostName: user.name,
              hostImage: user.profileImage,
              initialGoal: LiveGoal.fromJson(access.goal),
              initialGiftsTotal: access.totalGiftsValue,
              initialPremium: LivePremiumInfo.fromJson(access.premium),
            ),
          );
        } catch (_) {
          ToastHelper.showErrorToast(message: 'Failed to parse join response');
        }
    }
  }

  /// The host's still-running session, or null.
  Future<LiveSessionAccess?> fetchResumableLive() async {
    final result = await _getActiveLive(const NoParams());
    return result.dataOrNull;
  }

  /// Re-enters the same live session as host, with its goal (progress and
  /// status) restored from the server.
  void resumeLive(LiveSessionAccess access) {
    final liveStream = access.liveStream;
    final me = Get.find<SessionController>().session!.user!;
    Get.to(
      () => LiveStreamingScreen(
        token: access.token.toString(),
        roomName: access.roomName.toString(),
        host: _sfuHost,
        hostImage: me.profileImage,
        isHost: true,
        liveId: (access.raw['liveSessionId'] ?? liveStream['id']).toString(),
        hostId: me.id,
        streamTitle: liveStream['title']?.toString() ?? 'Live Stream',
        hostName: 'You',
        initialGoal: LiveGoal.fromJson(access.goal),
        initialGiftsTotal: access.totalGiftsValue,
        initialPremium: LivePremiumInfo.fromJson(access.premium),
        initialCallsOff: access.callsOff,
      ),
    );
  }

  /// "Go Live" button: resumes a running session if there is one, otherwise
  /// opens the setup screen for a new session.
  Future<void> openGoLive() async {
    if (_checkingResumable) return;
    _checkingResumable = true;
    try {
      final active = await fetchResumableLive();
      if (active != null) {
        resumeLive(active);
      } else {
        Get.to(() => const GoLiveSetupScreen());
      }
    } finally {
      _checkingResumable = false;
    }
  }

  /// On app launch: offers to go back to a live that is still running.
  Future<void> offerResumeIfLive() async {
    final active = await fetchResumableLive();
    if (active == null) return;

    final resume = await Get.dialog<bool>(
      const ResumeLiveDialog(),
      barrierDismissible: false,
    );

    if (resume == true) {
      // The server may have ended it while the dialog was open.
      final stillActive = await fetchResumableLive();
      if (stillActive != null) {
        resumeLive(stillActive);
      } else {
        ToastHelper.showInfoToast(message: 'That live has already ended');
      }
    } else if (resume == false) {
      await _endLive(const NoParams());
    }
  }

  /// Starts the broadcast from the Go Live setup screen and replaces that
  /// screen with the live room. Returns false (after an error toast) when
  /// the stream couldn't be started, so the host can try again.
  Future<bool> startLiveStream({
    int? goalAmount,
    String filterId = LiveFilters.none,
  }) async {
    final title =
        'live stream${Get.find<SessionController>().session!.user!.id}';

    final result = await _startLive(
      StartLiveParams(title: title, goalAmount: goalAmount),
    );

    switch (result) {
      case Err(:final failure):
        ToastHelper.showErrorToast(message: failure.message);
        return false;
      case Ok(data: final access):
        try {
          final liveStream = access.raw['liveStream'];
          final me = Get.find<SessionController>().session!.user!;
          // Replace the setup screen so leaving the live returns home.
          Get.off(
            () => LiveStreamingScreen(
              token: access.token,
              roomName: access.roomName,
              host: _sfuHost,
              hostImage: me.profileImage,
              isHost: true,
              liveId: liveStream['id'].toString(),
              hostId: me.id,
              streamTitle: liveStream['title'] ?? title,
              hostName: 'You',
              initialGoal: LiveGoal.fromJson(access.goal),
              initialFilterId: filterId,
            ),
          );
          return true;
        } catch (_) {
          ToastHelper.showErrorToast(message: "Couldn't start the live");
          return false;
        }
    }
  }
}
