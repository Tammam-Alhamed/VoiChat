import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/discover_repository.dart';

/// Online user counts per country, used to rank the country picker.
class GetCountryOnlineCounts extends UseCase<Map<String, int>, NoParams> {
  final DiscoverRepository _repository;

  const GetCountryOnlineCounts(this._repository);

  @override
  Future<Result<Map<String, int>>> call(NoParams params) {
    return _repository.getCountryOnlineCounts();
  }
}
