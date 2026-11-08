import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';
import '../../domain/entities/call_history.dart';
import '../models/call_history_model.dart';

/// Server calls for the Recent Calls tab.
abstract class RecentCallsRemoteDataSource {
  Future<List<CallHistory>> getCallHistory();

  /// Removes calls from this user's own history (the other participant's
  /// copy is untouched).
  Future<void> deleteCalls(List<String> callIds);
}

class RecentCallsRemoteDataSourceImpl implements RecentCallsRemoteDataSource {
  final ServiceHelper _serviceHelper;

  RecentCallsRemoteDataSourceImpl({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  @override
  Future<List<CallHistory>> getCallHistory() async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/calls/history',
      token: 'provide',
    );
    final List<dynamic> list = response.bodyOrThrow['data'];
    return list.map((e) => CallHistoryModel.fromJson(e)).toList();
  }

  @override
  Future<void> deleteCalls(List<String> callIds) async {
    await _serviceHelper.deleteHelper(
      target: '/v1/calls/history',
      token: 'provide',
      data: {'callIds': callIds},
    );
  }
}
