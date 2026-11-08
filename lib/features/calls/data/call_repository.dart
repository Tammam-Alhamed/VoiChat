import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/utils/api_status.dart';
import 'call_model.dart';

/// Repository that handles all call-related API requests.
///
/// Maps to backend routes:
///   POST /v1/calls/initiate
///   POST /v1/calls/:callId/answer
///   POST /v1/calls/:callId/end
///   POST /v1/calls/:callId/decline
///   POST /v1/calls/:callId/rate
///   GET  /v1/calls/history
///   GET  /v1/calls/missed
class CallRepository {
  final ServiceHelper _serviceHelper;
  final StoreHelper _storeHelper;

  CallRepository({
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
  }) : _serviceHelper = serviceHelper,
       _storeHelper = storeHelper;

  String get _token => _storeHelper.getAccessToken();

  // ─── Initiate a call ──────────────────────────────────────────────────────

  /// Initiates a call to [receiverId].
  /// Returns the call record, caller LiveKit token, and room name.
  Future<CallInitiateResponse?> initiateCall({
    required String receiverId,
    String callType = 'audio',
  }) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/calls/initiate',
      token: _token,
      data: {'receiverId': receiverId, 'callType': callType},
    );

    if (response is Success) {
      final body = _parseBody(response.data);
      if (body['success'] == true && body['data'] != null) {
        return CallInitiateResponse.fromJson(body['data']);
      }
    }
    if (response is Failure) {
      // One clear message (e.g. "User is busy on another call",
      // "Insufficient balance…") — shown once by CallsProvider._handleError
      // instead of this toast + a generic "Failed to initiate call".
      throw CallApiException(response.errorResponse.toString());
    }
    return null;
  }

  // ─── Answer a call ────────────────────────────────────────────────────────

  /// Answers an incoming call.
  /// Returns the call record, LiveKit token for the receiver, and room name.
  Future<CallAnswerResponse?> answerCall(String callId) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/calls/$callId/answer',
      token: _token,
      data: {'hi': 'hi'},
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          return CallAnswerResponse.fromJson(body['data']);
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.answerCall parse error: $e');
      }
    } else if (response is Failure) {
      Get.back();
      ToastHelper.showInfoToast(message: "The caller has ended this call");

      throw CallApiException(response.errorResponse.toString());
    }
    return null;
  }

  // ─── End a call ───────────────────────────────────────────────────────────

  /// Ends an active or ringing call.
  Future<CallModel?> endCall(String callId) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/calls/$callId/end',
      token: _token,
      data: {'hi': 'hi'},
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          return CallModel.fromJson(body['data']);
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.endCall parse error: $e');
      }
    } else if (response is Failure) {
      throw CallApiException(response.errorResponse.toString());
    }
    return null;
  }

  // ─── Decline a call ───────────────────────────────────────────────────────

  /// Declines an incoming call.
  Future<CallModel?> declineCall(String callId) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/calls/$callId/decline',
      token: _token,
      data: {'hi': 'hi'},
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          return CallModel.fromJson(body['data']);
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.declineCall parse error: $e');
      }
    } else if (response is Failure) {
      throw CallApiException(response.errorResponse.toString());
    }
    return null;
  }

  // ─── Rate a call ──────────────────────────────────────────────────────────

  /// Rates a completed call (caller only).
  Future<CallModel?> rateCall({
    required String callId,
    required int rating,
    String? comment,
  }) async {
    final response = await _serviceHelper.postHelper(
      target: '/v1/calls/$callId/rate',
      token: _token,
      data: {'rating': rating, if (comment != null) 'comment': comment},
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          return CallModel.fromJson(body['data']);
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.rateCall parse error: $e');
      }
    } else if (response is Failure) {
      throw CallApiException(response.errorResponse.toString());
    }
    return null;
  }

  // ─── Call history ─────────────────────────────────────────────────────────

  /// Fetches the call history for the current user.
  Future<List<CallHistoryItem>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/calls/history?page=$page&limit=$limit',
      token: _token,
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          final rawData = body['data'];
          final List items = rawData is List
              ? rawData
              : (rawData is Map && rawData['data'] is List)
              ? rawData['data']
              : [];
          return items.map((e) => CallHistoryItem.fromJson(e)).toList();
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.getCallHistory parse error: $e');
      }
    }
    return [];
  }

  /// Fetches missed calls for the current user.
  Future<List<CallHistoryItem>> getMissedCalls({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/calls/missed?page=$page&limit=$limit',
      token: _token,
    );

    if (response is Success) {
      try {
        final body = _parseBody(response.data);
        if (body['success'] == true && body['data'] != null) {
          final rawData = body['data'];
          final List items = rawData is List
              ? rawData
              : (rawData is Map && rawData['data'] is List)
              ? rawData['data']
              : [];
          return items.map((e) => CallHistoryItem.fromJson(e)).toList();
        }
      } catch (e) {
        if (kDebugMode) print('CallRepository.getMissedCalls parse error: $e');
      }
    }
    return [];
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseBody(dynamic data) {
    if (data is String) return jsonDecode(data);
    if (data is Map<String, dynamic>) return data;
    return {};
  }
}

/// Exception thrown when a call API request fails.
class CallApiException implements Exception {
  final String message;
  CallApiException(this.message);

  @override
  String toString() => 'CallApiException: $message';
}
