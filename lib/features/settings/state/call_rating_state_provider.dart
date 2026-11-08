import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';

import '../rate/feed_back_item.dart';

class CallRatingStateProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  CallRatingModel ratingData = CallRatingModel.empty();
  PageState pageState = PageState.loading;
  String? error;

  CallRatingStateProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  void retry() {
    pageState = PageState.loading;
    ratingData = CallRatingModel.empty();
    error = null;
    notifyListeners();
    getRatingSummary();
  }

  void setErrorState(String error) {
    this.error = error;
    pageState = PageState.error;
    notifyListeners();
  }

  void getRatingSummary() async {
    pageState = PageState.loading;
    notifyListeners();

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/calls/ratings/summary", // Matches backend route rule
      token: "provide",
    );

    if (response is Success) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.data);
        if (body['success'] == true && body['data'] != null) {
          ratingData = CallRatingModel.fromJson(body['data']);
          pageState = PageState.loaded;
        } else {
          setErrorState(body['message'] ?? 'Failed to load ratings summary');
        }
      } catch (e) {
        setErrorState('Error parsing ratings data');
      }
      notifyListeners();
    } else if (response is Failure) {
      setErrorState(response.errorResponse.toString());
    }
  }
}
