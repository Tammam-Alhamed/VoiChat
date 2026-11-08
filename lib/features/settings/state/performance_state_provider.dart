import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';

class PerformanceModel {
  final String period;
  final double earning;
  final int seconds;
  final int hours;
  final int minutes;
  final int totalViewers;
  final int totalStreams;
  final int newFollowers;

  PerformanceModel({
    required this.period,
    required this.earning,
    required this.seconds,
    required this.hours,
    required this.minutes,
    required this.totalViewers,
    required this.totalStreams,
    required this.newFollowers,
  });

  factory PerformanceModel.fromJson(Map<String, dynamic> json) {
    final streamTime = json['stream_time'] ?? {};
    return PerformanceModel(
      period: json['period']?.toString() ?? 'month',
      earning: (json['earning'] as num?)?.toDouble() ?? 0.0,
      seconds: (streamTime['seconds'] as num?)?.toInt() ?? 0,
      hours: (streamTime['hours'] as num?)?.toInt() ?? 0,
      minutes: (streamTime['minutes'] as num?)?.toInt() ?? 0,
      totalViewers: (json['total_viewers'] as num?)?.toInt() ?? 0,
      totalStreams: (json['total_streams'] as num?)?.toInt() ?? 0,
      newFollowers: (json['new_followers'] as num?)?.toInt() ?? 0,
    );
  }

  factory PerformanceModel.empty() {
    return PerformanceModel(
      period: 'month',
      earning: 0.0,
      seconds: 0,
      hours: 0,
      minutes: 0,
      totalViewers: 0,
      totalStreams: 0,
      newFollowers: 0,
    );
  }
}

class PerformanceStateProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  PerformanceModel performanceData = PerformanceModel.empty();
  PageState pageState = PageState.loading;
  String? error;
  String _selectedFilter = 'Month'; // Today, Week, Month

  String get selectedFilter => _selectedFilter;

  PerformanceStateProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  void setSelectedFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
    getPerformance();
  }

  void reset() {
    pageState = PageState.loading;
    performanceData = PerformanceModel.empty();
    error = null;
  }

  void retry() {
    pageState = PageState.loading;
    performanceData = PerformanceModel.empty();
    error = null;
    notifyListeners();
    getPerformance();
  }

  void setErrorState(String error) {
    this.error = error;
    pageState = PageState.error;
    notifyListeners();
  }

  void setEmptyState() {
    pageState = PageState.empty;
    notifyListeners();
  }

  void getPerformance() async {
    pageState = PageState.loading;
    notifyListeners();

    // Map UI filters to API parameters:
    // 'Today' -> 'day'
    // 'Week' -> 'week'
    // 'Month' -> 'month'
    String period = 'month';
    if (_selectedFilter == 'Today') {
      period = 'day';
    } else if (_selectedFilter == 'Week') {
      period = 'week';
    }

    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/performance?period=$period",
      token: "provide",
    );

    if (response is Success) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.data);
        if (body['success'] == true && body['data'] != null) {
          performanceData = PerformanceModel.fromJson(body['data']);
          pageState = PageState.loaded;
        } else {
          setErrorState(body['message'] ?? 'Failed to load performance data');
        }
      } catch (e) {
        setErrorState('Error parsing performance data');
      }
      notifyListeners();
    } else if (response is Failure) {
      setErrorState(response.errorResponse.toString());
    }
  }
}
