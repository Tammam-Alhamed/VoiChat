import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';

import 'creator_model.dart';

class ManageCreatorsProvider extends ChangeNotifier {
  final ServiceHelper _serviceHelper;

  List<CreatorModel> _allCreators = [];
  List<CreatorModel> filteredCreators = [];

  PageState pageState = PageState.loading;
  String? error;
  String _searchQuery = '';

  ManageCreatorsProvider({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  String get searchQuery => _searchQuery;

  /// Modifies local list state matching query instantly
  void searchCreatorsLocally(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      filteredCreators = List.from(_allCreators);
    } else {
      final lowercaseQuery = query.toLowerCase();
      filteredCreators = _allCreators.where((creator) {
        return creator.name.toLowerCase().contains(lowercaseQuery) ||
            creator.profileId.toLowerCase().contains(lowercaseQuery) ||
            creator.id.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchCreators() async {
    pageState = PageState.loading;
    notifyListeners();

    // Pulling matching limit structure used on your Performance endpoints
    ApiStatus response = await _serviceHelper.getHelper(
      target: "/v1/users/creators?page=1&limit=50",
      token: "provide",
    );

    if (response is Success) {
      final List dynamicList = jsonDecode(response.data)['data'];

      _allCreators = dynamicList
          .map((json) => CreatorModel.fromJson(json))
          .toList();

      // Re-apply filter rules smoothly onto newly delivered data pools
      searchCreatorsLocally(_searchQuery);
      pageState = filteredCreators.isEmpty ? PageState.empty : PageState.loaded;
    }
    if (response is Failure) {
      setErrorState(response.errorResponse.toString());
    }
    notifyListeners();
  }

  void setErrorState(String errorMessage) {
    error = errorMessage;
    pageState = PageState.error;
    notifyListeners();
  }
}
