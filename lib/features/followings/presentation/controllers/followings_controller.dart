import 'package:get/get.dart';

import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/enums/page_state.dart';
import '../../../../core/error/result.dart';
import '../../../session/presentation/controllers/session_controller.dart';
import '../../domain/usecases/get_followings.dart';

/// State of the Follow tab: the users the signed-in user follows.
class FollowingsController extends GetxController {
  final GetFollowings _getFollowings;

  FollowingsController({required GetFollowings getFollowings})
    : _getFollowings = getFollowings;

  PageState pageState = PageState.loading;
  List<ClientUser> followings = [];
  String? error;

  Future<void> getUserFollowings() async {
    pageState = PageState.loading;
    error = null;
    update();

    final String uid;
    try {
      uid = Get.find<SessionController>().session!.user!.id;
    } catch (e) {
      error = e.toString();
      pageState = PageState.error;
      update();
      return;
    }

    final result = await _getFollowings(uid);
    switch (result) {
      case Ok(:final data):
        followings = data;
        pageState = followings.isEmpty ? PageState.empty : PageState.loaded;
      case Err(:final failure):
        error = failure.message;
        pageState = PageState.error;
    }
    update();
  }
}
