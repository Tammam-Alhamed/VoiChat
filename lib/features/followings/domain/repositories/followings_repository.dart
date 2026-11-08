import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';

/// Contract for the list of users the signed-in user follows.
abstract class FollowingsRepository {
  Future<Result<List<ClientUser>>> getFollowings(String userId);
}
