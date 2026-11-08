import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';
import 'package:shoeebapk/core/helpers/toast_helper.dart';

import '../rate/feed_back_item.dart';

import '../../session/presentation/controllers/session_controller.dart';

class AccountSettingProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  CallRatingModel ratingData = CallRatingModel.empty();
  PageState pageState = PageState.loading;
  String? error;
  bool _isUpdating = false;

  AccountSettingProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  bool get isUpdating => _isUpdating;

  void retry() {
    pageState = PageState.loading;
    ratingData = CallRatingModel.empty();
    error = null;
    _isUpdating = false;
    notifyListeners();
  }

  void setErrorState(String error) {
    this.error = error;
    pageState = PageState.error;
    _isUpdating = false;
    notifyListeners();
  }

  /// Returns true on success, false on failure.
  /// UI should only dismiss its bottom sheet / dialog when this resolves to true.
  Future<bool> joinAgency({required String agentId}) async {
    if (_isUpdating) return false;
    _isUpdating = true;
    pageState = PageState.loading;
    notifyListeners();

    try {
      ApiStatus response = await _serviceHelper.putHelper(
        target: "/v1/users/join/agency/by-id",
        token: "provide",
        body: {'agentId': agentId},
      );

      if (response is Success) {
        final Map<String, dynamic> body = jsonDecode(response.data)['data'];
        _isUpdating = false;
        pageState = PageState.loaded;
        notifyListeners();

        ToastHelper.showSuccessToast(
          message: "You Joined ${body['referrer_name']}",
        );
        return true;
      } else if (response is Failure) {
        _isUpdating = false;
        pageState = PageState.error;
        error = response.errorResponse.toString();
        notifyListeners();

        ToastHelper.showErrorToast(message: response.errorResponse.toString());
        return false;
      }
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isUpdating = false;
      pageState = PageState.error;
      error = e.toString();
      notifyListeners();

      ToastHelper.showErrorToast(message: "An unexpected error occurred");
      return false;
    }
  }

  // ─── Add email / change phone (confirmed with a one-time code) ─────────────
  // The account's existing email can't be changed; a phone-only account can
  // add one. The phone number can be changed. Both need the code sent to the
  // NEW email / WhatsApp number (see backend accountContact.service).

  /// Sends the code. Returns true when it was sent.
  Future<bool> sendContactCode({
    required bool isPhone,
    required String value,
  }) async {
    if (_isUpdating) return false;
    _isUpdating = true;
    notifyListeners();

    final ApiStatus response = await _serviceHelper.postHelper(
      target: isPhone
          ? '/v1/users/contact/phone/send-code'
          : '/v1/users/contact/email/send-code',
      token: 'provide',
      data: {isPhone ? 'phone' : 'email': value},
    );

    _isUpdating = false;
    notifyListeners();

    if (response is Success) {
      ToastHelper.showSuccessToast(
        message: isPhone
            ? 'Code sent to your WhatsApp'
            : 'Code sent to your email',
      );
      return true;
    }
    if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
    return false;
  }

  /// Checks the code; on success saves the new email/phone everywhere in
  /// the app. Returns true on success.
  Future<bool> verifyContactCode({
    required BuildContext context,
    required bool isPhone,
    required String value,
    required String otp,
  }) async {
    if (_isUpdating) return false;
    _isUpdating = true;
    notifyListeners();

    final ApiStatus response = await _serviceHelper.postHelper(
      target: isPhone
          ? '/v1/users/contact/phone/verify'
          : '/v1/users/contact/email/verify',
      token: 'provide',
      data: {isPhone ? 'phone' : 'email': value, 'otp': otp},
    );

    _isUpdating = false;
    notifyListeners();

    if (response is Success) {
      try {
        final data = jsonDecode(response.data)['data'] as Map<String, dynamic>;
        if (context.mounted) {
          Get.find<SessionController>().updateEmailOrPhone(
            data['email']?.toString() ?? '',
            data['phone']?.toString() ?? '',
          );
        }
      } catch (e) {
        debugPrint('verifyContactCode parse error: $e');
      }
      ToastHelper.showSuccessToast(
        message: isPhone ? 'Phone number updated' : 'Email added',
      );
      return true;
    }
    if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
    return false;
  }

  @override
  void dispose() {
    _isUpdating = false;
    super.dispose();
  }
}
