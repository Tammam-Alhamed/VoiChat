import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';
import '../../../core/enums/page_state.dart';
import 'notification_model.dart'; // Adjust path
import 'promo_card_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  List<NotificationModel> notifications = [];
  List<PromoCardModel> promoCards = [];
  PageState pageState = PageState.loading;
  String? error;

  // Pagination variables
  int _currentPage = 1;
  final int _limit = 15;
  bool _hasMore = true;
  bool isLoadMoreLoading = false;
  int unreadCount = 0;

  NotificationsProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  void reset() {
    notifications.clear();
    promoCards.clear();
    pageState = PageState.loading;
    error = null;
    _currentPage = 1;
    _hasMore = true;
    isLoadMoreLoading = false;
    unreadCount = 0;
  }

  /// Fetch initial notifications (Page 1)
  Future<void> fetchNotifications() async {
    reset();
    notifyListeners();

    ApiStatus response = await _serviceHelper.getHelper(
      target:
          "/v1/notifications?page=$_currentPage&limit=$_limit", // Adjust target as needed
      token: "provider",
    );

    if (response is Success) {
      final decodedData = jsonDecode(response.data);
      final List<dynamic> dataList = decodedData['data'] ?? [];
      // Pagination totals, unreadCount, and promoCards all ride along in
      // `meta` (see ApiResponse.paginated on the backend) — they were
      // previously read off the top-level response object, where they
      // never actually existed, so unreadCount silently stayed 0 and
      // "load more" never triggered past page 1.
      final Map<String, dynamic> meta = decodedData['meta'] ?? {};

      unreadCount = meta['unreadCount'] ?? 0;
      notifications = dataList
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      final List<dynamic> promoCardList = meta['promoCards'] ?? [];
      promoCards = promoCardList
          .map((json) => PromoCardModel.fromJson(json))
          .toList();

      if (notifications.isEmpty && promoCards.isEmpty) {
        pageState = PageState.empty;
      } else {
        pageState = PageState.loaded;
        int total = meta['total'] ?? 0;
        _hasMore = notifications.length < total;
      }
    } else if (response is Failure) {
      error = response.errorResponse.toString();
      pageState = PageState.error;
    }
    notifyListeners();
  }

  /// Load more (Pagination)
  Future<void> loadMoreNotifications() async {
    if (isLoadMoreLoading || !_hasMore) return;

    isLoadMoreLoading = true;
    notifyListeners();

    _currentPage++;

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/notifications?page=$_currentPage&limit=$_limit",
      token: "provider",
    );

    if (response is Success) {
      final decodedData = jsonDecode(response.data);
      final List<dynamic> dataList = decodedData['data'] ?? [];
      final Map<String, dynamic> meta = decodedData['meta'] ?? {};

      final newItems = dataList
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        notifications.addAll(newItems);
        int total = meta['total'] ?? 0;
        _hasMore = notifications.length < total;
      }
    } else if (response is Failure) {
      _currentPage--;
    }

    isLoadMoreLoading = false;
    notifyListeners();
  }

  /// Mark notifications as read
  Future<void> markAsRead(List<String> notificationIds) async {
    ApiStatus response = await _serviceHelper.putHelper(
      target: "/v1/notifications/read",
      token: "provider",
      body: {"notificationIds": notificationIds},
    );

    if (response is Success) {
      for (var notification in notifications) {
        if (notificationIds.contains(notification.id)) {
          // This would ideally update a mutable field or we replace the object
          // For simplicity, relying on the backend state next refresh.
        }
      }
      unreadCount = (unreadCount - notificationIds.length).clamp(0, 999);
      notifyListeners();
    }
  }
}
