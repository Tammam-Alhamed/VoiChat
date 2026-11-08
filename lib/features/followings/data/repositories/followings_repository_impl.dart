import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/followings_repository.dart';
import '../datasources/followings_remote_data_source.dart';

class FollowingsRepositoryImpl implements FollowingsRepository {
  final FollowingsRemoteDataSource _remote;

  FollowingsRepositoryImpl({required FollowingsRemoteDataSource remote})
    : _remote = remote;

  @override
  Future<Result<List<ClientUser>>> getFollowings(String userId) {
    return guardResult(() => _remote.getFollowings(userId));
  }
}
