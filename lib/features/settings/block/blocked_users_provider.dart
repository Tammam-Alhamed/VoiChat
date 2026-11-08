import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';

import '../../../core/enums/page_state.dart';
import '../../../core/helpers/toast_helper.dart';
import 'blocked_model.dart';

class BlockedUsersProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  List<BlockedUser> blockedUsers = [];
  PageState pageState = PageState.loading;
  String? error;

  // متغيرات الـ Pagination
  int _currentPage = 1;
  final int _limit = 15;
  bool _hasMore = true;
  bool isLoadMoreLoading = false;

  // لودر خاص بعملية إلغاء الحظر لكل مستخدم على حدة (Map مشان ما يلفوا كلهم)
  final Map<String, bool> unblockLoaders = {};

  BlockedUsersProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  void reset() {
    blockedUsers.clear();
    pageState = PageState.loading;
    error = null;
    _currentPage = 1;
    _hasMore = true;
    isLoadMoreLoading = false;
    unblockLoaders.clear();
  }

  /// جلب قائمة المحظورين (الصفحة الأولى)
  Future<void> fetchBlockedUsers() async {
    reset();
    notifyListeners();

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/blocked?page=$_currentPage&limit=$_limit",
      token: "provider",
    );

    if (response is Success) {
      final decodedData = jsonDecode(response.data);
      final List<dynamic> dataList = decodedData['data'] ?? [];

      blockedUsers = dataList
          .map((json) => BlockedUser.fromJson(json))
          .toList();

      if (blockedUsers.isEmpty) {
        pageState = PageState.empty;
      } else {
        pageState = PageState.loaded;
        // فحص إذا لسا في صفحات تانية بناءً على الـ total
        int total = decodedData['total'] ?? 0;
        _hasMore = blockedUsers.length < total;
      }
    } else if (response is Failure) {
      error = response.errorResponse.toString();
      pageState = PageState.error;
    }
    notifyListeners();
  }

  /// جلب المزيد من البيانات عند السحب لأسفل (Load More)
  Future<void> loadMoreBlockedUsers() async {
    if (isLoadMoreLoading || !_hasMore) return;

    isLoadMoreLoading = true;
    notifyListeners();

    _currentPage++;

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/blocked?page=$_currentPage&limit=$_limit",
      token: "provider",
    );

    if (response is Success) {
      final decodedData = jsonDecode(response.data);
      final List<dynamic> dataList = decodedData['data'] ?? [];

      final newUsers = dataList
          .map((json) => BlockedUser.fromJson(json))
          .toList();

      if (newUsers.isEmpty) {
        _hasMore = false;
      } else {
        blockedUsers.addAll(newUsers);
        int total = decodedData['total'] ?? 0;
        _hasMore = blockedUsers.length < total;
      }
    } else if (response is Failure) {
      _currentPage--; // تراجع عن زيادة الصفحة إذا فشل الطلب
    }

    isLoadMoreLoading = false;
    notifyListeners();
  }

  /// إلغاء حظر مستخدم
  Future<void> unblockUser({
    required String userId,
    required String userName,
  }) async {
    if (unblockLoaders[userId] == true) return;

    unblockLoaders[userId] = true;
    notifyListeners();

    ApiStatus response = await _serviceHelper.deleteHelper(
      target: "/v1/users/$userId/unblock",
      token: "provider",
      data: {},
    );

    if (response is Success) {
      // حذف المستخدم من القائمة محلياً فوراً لتجربة مستخدم سريعة
      blockedUsers.removeWhere((user) => user.id == userId);
      unblockLoaders.remove(userId);

      if (blockedUsers.isEmpty) {
        pageState = PageState.empty;
      }

      ToastHelper.showSuccessToast(
        message: "unblock_success_message".trParams({"name": userName}),
      );
    } else if (response is Failure) {
      unblockLoaders[userId] = false;
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
    notifyListeners();
  }
}
