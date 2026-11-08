import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoeebapk/features/profile/profile_screen.dart';
import '../../core/helpers/store_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/utils/api_status.dart';
import '../../app/di/injection_container.dart';
import '../../core/widgets/premium_grid_card.dart';
import '../../core/assets_manager.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/domain/entities/client_user.dart';
import '../../core/data/models/client_user_model.dart';

class SearchByIdScreen extends StatefulWidget {
  const SearchByIdScreen({super.key});

  @override
  State<SearchByIdScreen> createState() => _SearchByIdScreenState();
}

class _SearchByIdScreenState extends State<SearchByIdScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClearIcon = false;
  bool _isLoading = false;
  bool _hasSearched = false;
  ClientUser? _searchResult;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _showClearIcon = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResult = null;
    });

    try {
      final storeHelper = sl<StoreHelper>();
      final serviceHelper = sl<ServiceHelper>();
      final token = storeHelper.getAccessToken();

      final endpoint =
          '/v1/users/search/profile-id?profileId=${Uri.encodeComponent(cleanQuery)}';
      final response = await serviceHelper.getHelper(
        target: endpoint,
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _searchResult = ClientUserModel.fromJson(body['data']);
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoading = false;
        _searchResult = null;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _searchResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: AppBar(
        backgroundColor: context.shellBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.shellTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: AppSearchField(
            controller: _searchController,
            autofocus: true,
            hintText: "Search by ID",
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            suffixIcon: _showClearIcon
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                        _searchResult = null;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB862E1)),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Search users by their 8-digit unique ID",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/noresultsearch.png",
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              "Oops, no results found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: context.shellTextPrimary,
              ),
            ),
          ],
        ),
      );
    }

    // Render exact match as a home tab style card in the correct grid aspect ratio
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        physics: const ClampingScrollPhysics(),
        children: [
          PremiumGridCard(
            bgUrl:
                _searchResult!.profileImage ??
                AssetsManager.defaultProfileImage,
            avatarUrl:
                _searchResult!.profileImage ??
                AssetsManager.defaultProfileImage,
            name: _searchResult!.name,
            diamonds: "",
            liveViews: "21",
            isLive: _searchResult!.isLive,
            isOnline: _searchResult!.isOnline,
            index: 1,
            userId: _searchResult!.id,
            viewsIconUrl: 'assets/icons/views.png',
            onTap: () => Get.to(
              () => TargetProfileScreen(
                userId: _searchResult!.id,
                userImage: _searchResult!.profileImage,
                userName: _searchResult!.name,
                index: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
