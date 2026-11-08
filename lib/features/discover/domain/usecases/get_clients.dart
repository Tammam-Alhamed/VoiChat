import '../../../../core/domain/entities/client_user.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/discover_repository.dart';

/// Loads the users of one Home sub-tab (all, live, online or by country).
class GetClients extends UseCase<List<ClientUser>, ClientsQuery> {
  final DiscoverRepository _repository;

  const GetClients(this._repository);

  @override
  Future<Result<List<ClientUser>>> call(ClientsQuery params) {
    return _repository.getClients(params);
  }
}
