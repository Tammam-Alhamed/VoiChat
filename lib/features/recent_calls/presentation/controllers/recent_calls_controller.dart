import 'package:get/get.dart';

import '../../../../core/enums/page_state.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/call_history.dart';
import '../../domain/usecases/delete_call_history.dart';
import '../../domain/usecases/get_call_history.dart';

/// State of the Recent Calls tab.
class RecentCallsController extends GetxController {
  final GetCallHistory _getCallHistory;
  final DeleteCallHistory _deleteCallHistory;

  RecentCallsController({
    required GetCallHistory getCallHistory,
    required DeleteCallHistory deleteCallHistory,
  }) : _getCallHistory = getCallHistory,
       _deleteCallHistory = deleteCallHistory;

  List<CallHistory> calls = [];
  PageState pageState = PageState.loading;
  String? error;

  /// Back to the initial loading state, silently.
  void reset() {
    pageState = PageState.loading;
    calls = [];
    error = null;
  }

  void retry() {
    pageState = PageState.loading;
    calls = [];
    error = null;
    update();
    getRecentCall();
  }

  void setErrorState(String error) {
    this.error = error;
    pageState = PageState.error;
    update();
  }

  void setEmptyState() {
    pageState = PageState.empty;
    update();
  }

  Future<void> getRecentCall() async {
    final result = await _getCallHistory(const NoParams());
    switch (result) {
      case Ok(:final data):
        if (data.isEmpty) {
          setEmptyState();
          return;
        }
        calls = data;
        pageState = PageState.loaded;
        update();
      case Err(:final failure):
        setErrorState(failure.message);
    }
  }

  /// Optimistically removes [ids] from the list, then deletes them on the
  /// server in a single request (fire-and-forget).
  void deleteCalls(Set<String> ids) {
    calls.removeWhere((c) => ids.contains(c.id));
    if (calls.isEmpty) {
      setEmptyState();
    } else {
      update();
    }
    _deleteCallHistory(ids.toList());
  }
}
