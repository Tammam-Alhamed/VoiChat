import '../../../../core/data/models/client_user_model.dart';
import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';

/// Server calls for the Follow tab.
abstract class FollowingsRemoteDataSource {
  /// Users that [userId] follows.
  Future<List<ClientUser>> getFollowings(String userId);
}

class FollowingsRemoteDataSourceImpl implements FollowingsRemoteDataSource {
  final ServiceHelper _serviceHelper;

  FollowingsRemoteDataSourceImpl({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  @override
  Future<List<ClientUser>> getFollowings(String userId) async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/users/$userId/following',
      token: 'provide',
    );
    final Map<String, dynamic> body = response.bodyOrThrow;
    final List<dynamic> list = body['data'] ?? [];
    return list.map((e) => ClientUserModel.fromJson(e)).toList();
  }
}
