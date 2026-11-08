import 'dart:convert';

import '../../../../core/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';
import '../../../../core/utils/api_status.dart';
import '../../domain/entities/live_session_access.dart';

/// HTTP calls for entering and leaving live rooms.
abstract class LiveRemoteDataSource {
  Future<LiveSessionAccess> joinLive(String liveId);

  Future<LiveSessionAccess> startLive({required String title, int? goalAmount});

  Future<LiveSessionAccess?> getActiveLive();

  Future<void> endLive();
}

class LiveRemoteDataSourceImpl implements LiveRemoteDataSource {
  final ServiceHelper _serviceHelper;

  LiveRemoteDataSourceImpl({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  /// Reads `{ success, data, message }`. A non-success body becomes a
  /// [ServerException] carrying the server message or [fallbackMessage];
  /// an unreadable body uses [parseErrorMessage].
  LiveSessionAccess _parseAccess(
    ApiStatus response, {
    required String fallbackMessage,
    required String parseErrorMessage,
  }) {
    if (response is! Success) throw response.toServerException();

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.data as String) as Map<String, dynamic>;
    } catch (_) {
      throw ServerException(
        code: Constants.invalidFormat,
        message: parseErrorMessage,
      );
    }

    if (body['success'] == true && body['data'] != null) {
      return LiveSessionAccess(Map<String, dynamic>.from(body['data']));
    }
    throw ServerException(
      code: Constants.invalidResponse,
      message: body['message']?.toString() ?? fallbackMessage,
    );
  }

  @override
  Future<LiveSessionAccess> joinLive(String liveId) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/live/$liveId/join',
      data: {'hi': 'pk'},
      token: 'provide',
    );
    return _parseAccess(
      response,
      fallbackMessage: 'Failed to join live room',
      parseErrorMessage: 'Failed to parse join response',
    );
  }

  @override
  Future<LiveSessionAccess> startLive({
    required String title,
    int? goalAmount,
  }) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/live/start',
      token: 'provide',
      data: {'title': title, if (goalAmount != null) 'goalAmount': goalAmount},
    );
    return _parseAccess(
      response,
      fallbackMessage: "Couldn't start the live",
      parseErrorMessage: "Couldn't start the live",
    );
  }

  @override
  Future<LiveSessionAccess?> getActiveLive() async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/live/me/active',
      token: 'provide',
    );
    if (response is! Success) return null;
    try {
      final body = response.bodyOrThrow;
      final data = body is Map ? body['data'] : null;
      return data is Map<String, dynamic> ? LiveSessionAccess(data) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> endLive() async {
    await _serviceHelper.postHelper(
      target: '/v1/live/end',
      token: 'provide',
      data: const {},
    );
  }
}
