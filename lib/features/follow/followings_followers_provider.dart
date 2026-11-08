import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/constants.dart';
import 'package:shoeebapk/core/helpers/toast_helper.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';

import 'follow_user_model.dart';

enum FollowPageState { loading, loaded, error, empty }

class FollowingProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  List<FollowUserModel> _allFollowers = [];
  List<FollowUserModel> _allFollowing = [];

  List<FollowUserModel> filteredFollowers = [];
  List<FollowUserModel> filteredFollowing = [];

  FollowPageState followersState = FollowPageState.loading;
  FollowPageState followingState = FollowPageState.loading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  FollowingProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  /// Performs instant filter updates locally without remote DB interaction
  void updateLocalSearch(String query) {
    _searchQuery = query;
    final lowercaseQuery = query.toLowerCase();

    if (query.isEmpty) {
      filteredFollowers = List.from(_allFollowers);
      filteredFollowing = List.from(_allFollowing);
    } else {
      filteredFollowers = _allFollowers
          .where((u) => u.name.toLowerCase().contains(lowercaseQuery))
          .toList();
      filteredFollowing = _allFollowing
          .where((u) => u.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadFollowers(
    String userId, {
    String token = "provide",
    bool silent = false,
  }) async {
    _ownerId = userId;
    if (!silent) {
      followersState = FollowPageState.loading;
      notifyListeners();
    }

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/$userId/followers?page=1&limit=50",
      token: token,
    );

    if (response is Success) {
      final List dynamicList = jsonDecode(response.data)['data'] ?? [];
      _allFollowers = dynamicList
          .map((j) => FollowUserModel.fromJson(j))
          .toList();

      _applyFollowersFilter();
    }

    notifyListeners();
  }

  Future<void> loadFollowing(
    String userId, {
    String token = "provide",
    bool silent = false,
  }) async {
    _ownerId = userId;
    if (!silent) {
      followingState = FollowPageState.loading;
      notifyListeners();
    }

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/$userId/following?page=1&limit=50",
      token: token,
    );

    if (response is Success) {
      final List dynamicList = jsonDecode(response.data)['data'] ?? [];
      _allFollowing = dynamicList
          .map((j) => FollowUserModel.fromJson(j))
          .toList();

      _applyFollowingFilter();
    }
    notifyListeners();
  }

  String? _ownerId; // whose lists are loaded (the signed-in user)
  final Set<String> _busyIds = {};
  bool isBusy(String userId) => _busyIds.contains(userId);

  /// Heart tap: follow if I don't follow them yet, otherwise unfollow.
  /// Updates both lists immediately, then confirms with the server (and
  /// rolls back if the server refuses).
  Future<void> toggleFollow(FollowUserModel user, {String? ownerId}) async {
    if (_busyIds.contains(user.id)) return;
    _ownerId = ownerId ?? _ownerId;
    final follow = !user.isFollowing;

    _busyIds.add(user.id);
    _setFollowingLocally(user.id, follow);

    final ApiStatus response = follow
        ? await _serviceHelper.postHelper(
            target: '/v1/users/${user.id}/follow',
            token: 'provide',
            data: const {},
          )
        : await _serviceHelper.deleteHelper(
            target: '/v1/users/${user.id}/unfollow',
            token: 'provide',
          );

    _busyIds.remove(user.id);

    if (response is Success) {
      if (!follow) {
        // No longer following → leaves my "Following" list.
        _allFollowing.removeWhere((u) => u.id == user.id);
        _applyFollowingFilter();
      } else if (!_allFollowing.any((u) => u.id == user.id) &&
          _ownerId != null) {
        // Newly followed → shows up in "Following" too.
        loadFollowing(_ownerId!, silent: true);
      }
      notifyListeners();
      return;
    }

    // Server said no (or no internet): undo, then resync with the server.
    _setFollowingLocally(user.id, !follow);
    if (response is Failure && response.code == Constants.noInternet) {
      ToastHelper.showErrorToast(message: 'No Internet Connection');
    }
    if (_ownerId != null) {
      loadFollowers(_ownerId!, silent: true);
      loadFollowing(_ownerId!, silent: true);
    }
  }

  void _setFollowingLocally(String userId, bool value) {
    for (final u in [..._allFollowers, ..._allFollowing]) {
      if (u.id == userId) u.isFollowing = value;
    }
    notifyListeners();
  }

  void _applyFollowersFilter() {
    if (_searchQuery.isEmpty) {
      filteredFollowers = List.from(_allFollowers);
    } else {
      filteredFollowers = _allFollowers
          .where(
            (u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    followersState = filteredFollowers.isEmpty
        ? FollowPageState.empty
        : FollowPageState.loaded;
  }

  void _applyFollowingFilter() {
    if (_searchQuery.isEmpty) {
      filteredFollowing = List.from(_allFollowing);
    } else {
      filteredFollowing = _allFollowing
          .where(
            (u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    followingState = filteredFollowing.isEmpty
        ? FollowPageState.empty
        : FollowPageState.loaded;
  }
}
