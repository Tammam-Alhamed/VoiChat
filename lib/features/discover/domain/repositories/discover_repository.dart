import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';

/// Filters for one Home sub-tab request.
class ClientsQuery {
  final int page;
  final int limit;
  final bool isLive;
  final bool isOnline;
  final String? country;

  const ClientsQuery({
    this.page = 1,
    this.limit = 20,
    this.isLive = false,
    this.isOnline = false,
    this.country,
  });
}

/// Contract for discovering users on the Home tab.
abstract class DiscoverRepository {
  Future<Result<List<ClientUser>>> getClients(ClientsQuery query);

  Future<Result<Map<String, int>>> getCountryOnlineCounts();
}
