import '../../../../core/helpers/device_info_helper.dart';
import '../../../../core/helpers/store_helper.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';
import '../../../../core/utils/api_status.dart';
import '../../domain/entities/app_status.dart';
import '../models/session_data_model.dart';

/// Server calls that validate and refresh the current session.
abstract class SessionRemoteDataSource {
  /// Asks the server whether this device and token may use the app.
  Future<AppStatus> checkStatus();

  /// Registers [fcmToken] for push notifications. Returns true on success.
  Future<bool> uploadFcmToken(String fcmToken);
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final ServiceHelper _serviceHelper;
  final StoreHelper _storeHelper;

  SessionRemoteDataSourceImpl({
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
  }) : _serviceHelper = serviceHelper,
       _storeHelper = storeHelper;

  @override
  Future<AppStatus> checkStatus() async {
    final deviceId = await DeviceInfoHelper.getDeviceId();
    final token = _storeHelper.getAccessToken();

    final response = await _serviceHelper.postHelper(
      target: '/v1/auth/check-status',
      data: {'deviceId': deviceId},
      token: token != 'token' ? token : null,
    );

    final body = response.bodyOrThrow;
    if (body['success'] != true) return const AppStatusUnavailable();

    final data = body['data'];
    if (data['isBlocked'] == true) {
      return AppStatusBlocked(
        data['reason'] ?? 'You have been blocked from using this app.',
      );
    }

    // optionalAuth on the server lets an unknown token through instead of
    // answering 401, so a missing user means the session itself is gone.
    if (data['user'] == null) return const AppStatusSessionExpired();

    return AppStatusActive(SessionDataModel.fromJson(data));
  }

  @override
  Future<bool> uploadFcmToken(String fcmToken) async {
    final status = await _serviceHelper.postHelper(
      target: '/v1/users/fcm-token',
      token: 'provide',
      data: {'fcmToken': fcmToken},
    );
    return status is Success;
  }
}
