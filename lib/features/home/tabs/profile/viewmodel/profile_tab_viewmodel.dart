import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../../../core/enums/page_state.dart';
import '../../../../../core/network/service_helper.dart';
import '../../../../../core/helpers/store_helper.dart';
import '../../../../../core/utils/api_status.dart';
import '../../../../profile/data/post_model.dart';
import '../data/my_profile_model.dart';

class ProfileTabViewModel extends ChangeNotifier {
  final ServiceHelper _serviceHelper;
  final StoreHelper _storeHelper;

  ProfileTabViewModel({
    required ServiceHelper serviceHelper,
    required StoreHelper storeHelper,
  }) : _serviceHelper = serviceHelper,
       _storeHelper = storeHelper;

  // ── Page-level state (drives which top-level widget is shown) ──────────
  PageState pageState = PageState.loading;
  String? error;

  // ── In-place busy flag for actions that shouldn't hide the loaded UI ───
  // (avatar update/remove, add/delete post). The screen stays on
  // PageState.loaded and just shows a small progress indicator via this flag.
  bool isBusy = false;

  MyProfileResponse? profile;

  List<PostModel> posts = [];

  bool get isLoading => pageState == PageState.loading;

  void reset() {
    pageState = PageState.loading;
    profile = null;
    posts = [];
    error = null;
  }

  void retry() {
    reset();
    notifyListeners();
    getMyProfile();
  }

  void _setErrorState(String message) {
    error = message;
    pageState = PageState.error;
    notifyListeners();
  }

  void _setEmptyState() {
    pageState = PageState.empty;
    notifyListeners();
  }

  void getMyProfile() async {
    pageState = PageState.loading;

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/me",
      token: "provide", // تركناها كرمال الكلاس المساعد يقرأ التوكن صح
    );

    if (response is Success) {
      profile = MyProfileResponse.fromJson(jsonDecode(response.data));

      // إذا نجح الفحص ولم يكن محظوراً أو مبلكاً
      pageState = PageState.loaded;
      notifyListeners();
    } else if (response is Failure) {
      _setErrorState(response.errorResponse.toString());
    }
  }

  Future<void> fetchMyPosts() async {
    final token = _storeHelper.getAccessToken();
    final response = await _serviceHelper.getHelper(
      target: '/v1/posts/user/ef1e403d-cebd-49cb-87f4-60eb7b9206a3',
      token: token,
    );

    if (response is Success) {
      try {
        final body = jsonDecode(response.data);

        if (body['success'] == true && body['data'] != null) {
          final raw = body['data'];
          final list = raw is List ? raw : [];
          posts = list
              .whereType<Map<String, dynamic>>()
              .map(PostModel.fromJson)
              .toList();
        }
      } catch (e) {
        if (kDebugMode) print('ProfileTabViewModel.fetchMyPosts error: $e');
      }
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    isBusy = true;
    notifyListeners();

    try {
      final multipartFile = await _serviceHelper.createMultipartFile(
        'profile_image',
        imageFile,
      );

      final response = await _serviceHelper.putMultipartHelper(
        target: '/v1/users/profile',
        files: [multipartFile],
        fields: {},
        token: _storeHelper.getAccessToken(),
      );

      if (response is Success) {
        final body = jsonDecode(response.data);
        if (body['success'] == true && body['data'] != null) {
          profile!.data = UserProfile.fromJson(body['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileTabViewModel.updateProfileImage error: $e');
      }
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> removeProfileImage() async {
    isBusy = true;
    notifyListeners();

    try {
      final response = await _serviceHelper.putHelper(
        target: '/v1/users/profile',
        body: {'profile_image': ''},
        token: _storeHelper.getAccessToken(),
      );

      if (response is Success) {
        final body = jsonDecode(response.data);
        if (body['success'] == true && body['data'] != null) {
          profile!.data = UserProfile.fromJson(body['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileTabViewModel.removeProfileImage error: $e');
      }
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> addPost(File mediaFile) async {
    isBusy = true;
    notifyListeners();

    try {
      final multipartFile = await _serviceHelper.createMultipartFile(
        'media',
        mediaFile,
      );

      final response = await _serviceHelper.postMultipartHelper(
        target: '/v1/posts',
        files: [multipartFile],
        fields: {},
        token: _storeHelper.getAccessToken(),
      );

      if (response is Success) {
        await fetchMyPosts();
      }
    } catch (e) {
      if (kDebugMode) print('ProfileTabViewModel.addPost error: $e');
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    isBusy = true;
    notifyListeners();

    try {
      final response = await _serviceHelper.deleteHelper(
        target: '/v1/posts/$postId',
        token: _storeHelper.getAccessToken(),
      );

      if (response is Success) {
        await fetchMyPosts();
      }
    } catch (e) {
      if (kDebugMode) print('ProfileTabViewModel.deletePost error: $e');
    }

    isBusy = false;
    notifyListeners();
  }
}
