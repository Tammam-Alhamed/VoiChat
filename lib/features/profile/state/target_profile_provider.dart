import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';
import 'package:shoeebapk/features/profile/data/profile_response.dart';
import 'package:shoeebapk/core/helpers/toast_helper.dart';
import '../data/user_profile_model.dart';
import 'profile_page_state.dart';

class TargetProfileProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  bool followLoader = false;
  UserProfile? profile;
  String targetId = "0";

  ProfilePageState pageState = ProfilePageState.loading;
  String? error;
  String? banReason; // لتخزين سبب الحظر وعرضه في الـ UI

  TargetProfileProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  void reset({required String userId}) {
    targetId = userId;
    pageState = ProfilePageState.loading;
    profile = null;
    followLoader = false;
    error = null;
    banReason = null;
  }

  void retry() {
    pageState = ProfilePageState.loading;
    profile = null;
    error = null;
    banReason = null;
    followLoader = false;
    notifyListeners();
    getProfile(userId: targetId);
  }

  void setErrorState(String error) {
    this.error = error;
    followLoader = false;
    pageState = ProfilePageState.error;
    notifyListeners();
  }

  void setEmptyState() {
    pageState = ProfilePageState.empty;
    notifyListeners();
  }

  /// جلب بيانات البروفايل وتهندل الحالات المتقدمة (Banned / Blocked)
  void getProfile({required String userId}) async {
    targetId = userId;

    pageState = ProfilePageState.loading;
    notifyListeners();

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/$userId/profile",
      token: "provide", // تركناها كرمال الكلاس المساعد يقرأ التوكن صح
    );

    if (response is Success) {
      UserProfileResponse profileResponse = UserProfileResponse.fromJson(
        jsonDecode(response.data),
      );
      profile = profileResponse.data;

      if (profile == null) {
        setEmptyState();
        return;
      }

      // ─── فحص حالات الحظر والبلوك وترتيب الأولوية ───
      if (profile!.isBanned == true) {
        banReason = profile!.banReason ?? "This account has been suspended";
        pageState = ProfilePageState.banned;
        notifyListeners();
        return;
      }

      if (profile!.isBlocked == true) {
        pageState = ProfilePageState.blocked;
        notifyListeners();
        return;
      }

      // إذا نجح الفحص ولم يكن محظوراً أو مبلكاً
      pageState = ProfilePageState.loaded;
      notifyListeners();
    } else if (response is Failure) {
      setErrorState(response.errorResponse.toString());
    }
  }

  /// متابعة مستخدم
  void followUser({required String userId}) async {
    if (followLoader) return;

    followLoader = true;
    notifyListeners();

    ApiStatus response = await _serviceHelper.postHelper(
      target: "/v1/users/$userId/follow",
      token: "provider",
      data: {'hi': 'hi'},
    );

    if (response is Success) {
      increaseFollowersCount();
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }

    followLoader = false;
    notifyListeners();
  }

  /// إلغاء متابعة مستخدم
  void unFollowUser({required String userId}) async {
    if (followLoader) return;

    followLoader = true;
    notifyListeners();

    ApiStatus response = await _serviceHelper.deleteHelper(
      target: "/v1/users/$userId/unfollow",
      token: "provider",
      data: {'hi': 'hi'},
    );

    if (response is Success) {
      decreaseFollowersCount();
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }

    followLoader = false;
    notifyListeners();
  }

  void increaseFollowersCount({int amount = 1}) {
    if (profile == null) return;
    profile!.followersCount += amount;
    profile!.isFollowing = true;
    notifyListeners();
  }

  void decreaseFollowersCount({int amount = 1}) {
    if (profile == null) return;
    profile!.isFollowing = false;
    if (profile!.followersCount >= amount) {
      profile!.followersCount -= amount;
    } else {
      profile!.followersCount = 0;
    }
    notifyListeners();
  }

  // لودرات خاصة بالحظر والإبلاغ مشان جودة الـ UI
  bool blockLoader = false;
  bool reportLoader = false;

  /// حظر مستخدم
  void blockUser({required String userId, required String userName}) async {
    if (blockLoader) return;

    blockLoader = true;
    notifyListeners();

    ApiStatus response = await _serviceHelper.postHelper(
      target: "/v1/users/$userId/block",
      token: "provider",
      data: {},
    );

    if (response is Success) {
      Get.back(); // نسكر الديايلوج فوراً

      // منغير حالة الصفحة فوراً لـ blocked مشان الـ UI يتحدث وما يضل شايف بروفايل الشخص
      pageState = ProfilePageState.blocked;

      ToastHelper.showSuccessToast(message: "تم حظر $userName بنجاح.");
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }

    blockLoader = false;
    notifyListeners();
  }

  /// الإبلاغ عن مستخدم
  void reportUser({
    required String userId,
    required String userName,
    required String reason,
    required String description,
  }) async {
    if (reportLoader) return;

    reportLoader = true;
    notifyListeners();

    ApiStatus response = await _serviceHelper.postHelper(
      target: "/v1/users/$userId/report",
      token: "provider",
      data: {"reason": reason, "description": description},
    );

    if (response is Success) {
      Get.back(); // نسكر ديايلوج الإبلاغ
      ToastHelper.showSuccessToast(
        message: "تم تقديم البلاغ ضد $userName بنجاح.",
      );
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }

    reportLoader = false;
    notifyListeners();
  }
}
