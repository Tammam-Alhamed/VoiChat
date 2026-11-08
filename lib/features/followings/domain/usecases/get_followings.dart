import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/followings_repository.dart';

/// Loads the users followed by the given user id.
class GetFollowings extends UseCase<List<ClientUser>, String> {
  final FollowingsRepository _repository;

  const GetFollowings(this._repository);

  @override
  Future<Result<List<ClientUser>>> call(String userId) {
    return _repository.getFollowings(userId);
  }
}
