import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_data_source.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  final DiscoverRemoteDataSource _remote;

  DiscoverRepositoryImpl({required DiscoverRemoteDataSource remote})
    : _remote = remote;

  @override
  Future<Result<List<ClientUser>>> getClients(ClientsQuery query) {
    return guardResult(() => _remote.getClients(query));
  }

  @override
  Future<Result<Map<String, int>>> getCountryOnlineCounts() {
    return guardResult(_remote.getCountryOnlineCounts);
  }
}
