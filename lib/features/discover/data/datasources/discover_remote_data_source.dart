import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/data/models/client_user_model.dart';
import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/service_helper.dart';
import '../../../../core/utils/api_status.dart';
import '../../domain/repositories/discover_repository.dart';

/// Server calls behind the Home tab's user lists.
abstract class DiscoverRemoteDataSource {
  /// Lists users for one Home sub-tab. Any failure yields an empty list,
  /// which the tab renders as its empty state.
  Future<List<ClientUser>> getClients(ClientsQuery query);

  /// Number of online users per country code.
  Future<Map<String, int>> getCountryOnlineCounts();
}

class DiscoverRemoteDataSourceImpl implements DiscoverRemoteDataSource {
  final ServiceHelper _serviceHelper;

  DiscoverRemoteDataSourceImpl({required ServiceHelper serviceHelper})
    : _serviceHelper = serviceHelper;

  @override
  Future<List<ClientUser>> getClients(ClientsQuery query) async {
    var endpoint = '/v1/users/clients?page=${query.page}&limit=${query.limit}';
    if (query.isLive) endpoint += '&is_live=true';
    if (query.isOnline) endpoint += '&is_online=true';
    final country = query.country;
    if (country != null && country.isNotEmpty) {
      endpoint += '&country=${Uri.encodeComponent(country)}';
    }

    final response = await _serviceHelper.getHelper(
      target: endpoint,
      token: 'provide',
    );

    if (response is! Success) {
      if (response is Failure && kDebugMode) {
        debugPrint('DiscoverRemoteDataSource error: ${response.errorResponse}');
      }
      return [];
    }

    try {
      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      if (body['success'] != true) return [];

      final raw = body['data'];
      if (raw == null) return [];

      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List ? raw['data'] as List : []);

      return list
          .whereType<Map<String, dynamic>>()
          .map(ClientUserModel.fromJson)
          .toList();
    } catch (e, st) {
      if (kDebugMode)
        debugPrint('DiscoverRemoteDataSource parse error: $e\n$st');
      return [];
    }
  }

  @override
  Future<Map<String, int>> getCountryOnlineCounts() async {
    final response = await _serviceHelper.getHelper(
      target: '/v1/users/countries/online-counts',
      token: 'provide',
    );

    List<dynamic> rows = const [];
    if (response is Success) {
      final body = response.bodyOrThrow;
      if (body is Map && body['success'] == true && body['data'] is List) {
        rows = body['data'] as List;
      }
    }

    final counts = <String, int>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final code = row['country']?.toString();
      if (code == null || code.isEmpty) continue;
      final rawCount = row['count'];
      counts[code] = rawCount is int
          ? rawCount
          : int.tryParse(rawCount.toString()) ?? 0;
    }
    return counts;
  }
}
