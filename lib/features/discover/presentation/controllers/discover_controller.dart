import 'package:get/get.dart';

import '../../../../core/domain/entities/client_user.dart';
import '../../domain/repositories/discover_repository.dart';
import '../../domain/usecases/get_clients.dart';

enum TabStatus { idle, loading, loaded, error }

/// Loading state and items of one Home sub-tab.
class TabState {
  final TabStatus status;
  final List<ClientUser> items;

  const TabState({this.status = TabStatus.idle, this.items = const []});

  TabState copyWith({TabStatus? status, List<ClientUser>? items}) =>
      TabState(status: status ?? this.status, items: items ?? this.items);

  bool get isLoading => status == TabStatus.loading;
  bool get isEmpty => !isLoading && items.isEmpty;
}

/// State of the Home tab: four independently loaded user lists (Home, Live,
/// Online, Country) kept in sync with realtime presence events.
class DiscoverController extends GetxController {
  final GetClients _getClients;

  DiscoverController({required GetClients getClients})
    : _getClients = getClients;

  TabState _home = const TabState();
  TabState _live = const TabState();
  TabState _online = const TabState();
  TabState _country = const TabState();

  TabState get homeState => _home;
  TabState get liveState => _live;
  TabState get onlineState => _online;
  TabState get countryState => _country;

  String? _selectedCountry;
  String? get selectedCountry => _selectedCountry;

  bool isTabLoading(String tab) => _stateOf(tab)?.isLoading ?? false;

  bool isTabEmpty(String tab) => _stateOf(tab)?.isEmpty ?? true;

  List<ClientUser> dataForTab(String tab) => _stateOf(tab)?.items ?? [];

  TabState? _stateOf(String tab) {
    switch (tab) {
      case 'Home':
        return _home;
      case 'Live':
        return _live;
      case 'Online':
        return _online;
      case 'Country':
        return _country;
      default:
        return null;
    }
  }

  /// Loads every sub-tab at once (pull-to-refresh-all). Regular tab
  /// switching uses [fetchTabIfIdle] so each sub-tab loads on demand.
  Future<void> fetchAll() => Future.wait([
    fetchHomeClients(),
    fetchActiveLives(),
    fetchOnlineClients(),
    fetchCountryClients(),
  ]);

  /// Loads a sub-tab the first time it becomes visible; switching back and
  /// forth never re-fetches.
  Future<void> fetchTabIfIdle(String tab) {
    switch (tab) {
      case 'Home':
        if (_home.status == TabStatus.idle) return fetchHomeClients();
        break;
      case 'Live':
        if (_live.status == TabStatus.idle) return fetchActiveLives();
        break;
      case 'Online':
        if (_online.status == TabStatus.idle) return fetchOnlineClients();
        break;
      case 'Country':
        if (_country.status == TabStatus.idle) return fetchCountryClients();
        break;
    }
    return Future.value();
  }

  Future<List<ClientUser>> _load(ClientsQuery query) async {
    final result = await _getClients(query);
    return result.dataOrNull ?? [];
  }

  Future<void> fetchHomeClients({int page = 1, int limit = 20}) async {
    if (_home.isLoading) return;
    _home = _home.copyWith(status: TabStatus.loading);
    update();
    final items = await _load(ClientsQuery(page: page, limit: limit));
    _home = TabState(status: TabStatus.loaded, items: items);
    update();
  }

  Future<void> fetchActiveLives({int page = 1, int limit = 20}) async {
    if (_live.isLoading) return;
    _live = _live.copyWith(status: TabStatus.loading);
    update();
    final items = await _load(
      ClientsQuery(page: page, limit: limit, isLive: true),
    );
    _live = TabState(status: TabStatus.loaded, items: items);
    update();
  }

  Future<void> fetchOnlineClients({int page = 1, int limit = 20}) async {
    if (_online.isLoading) return;
    _online = _online.copyWith(status: TabStatus.loading);
    update();
    final items = await _load(
      ClientsQuery(page: page, limit: limit, isOnline: true),
    );
    _online = TabState(status: TabStatus.loaded, items: items);
    update();
  }

  Future<void> fetchCountryClients({int page = 1, int limit = 20}) async {
    if (_country.isLoading) return;
    _country = _country.copyWith(status: TabStatus.loading);
    update();
    final items = await _load(
      ClientsQuery(page: page, limit: limit, country: _selectedCountry),
    );
    _country = TabState(status: TabStatus.loaded, items: items);
    update();
  }

  Future<void> setCountryFilter(String? country) async {
    _selectedCountry = country;
    update();
    await fetchCountryClients();
  }

  Future<void> refreshTab(String tab) {
    switch (tab) {
      case 'Home':
        return fetchHomeClients();
      case 'Live':
        return fetchActiveLives();
      case 'Online':
        return fetchOnlineClients();
      case 'Country':
        return fetchCountryClients();
      default:
        return Future.value();
    }
  }

  /// Applies [change] to the user [userId] in every sub-tab, then rebuilds.
  void _updateEverywhere(String userId, void Function(ClientUser user) change) {
    List<ClientUser> apply(List<ClientUser> users) => users.map((user) {
      if (user.id == userId) change(user);
      return user;
    }).toList();

    _home = _home.copyWith(items: apply(_home.items));
    _live = _live.copyWith(items: apply(_live.items));
    _online = _online.copyWith(items: apply(_online.items));
    _country = _country.copyWith(items: apply(_country.items));
    update();
  }

  /// Realtime: [userId] started broadcasting [stream].
  void onUserLive(String userId, LiveStream stream) {
    _updateEverywhere(userId, (user) {
      user.isLive = true;
      user.streams!.add(stream);
    });
  }

  /// Realtime: [userId] ended their broadcast.
  void onUserEndLive(String userId) {
    _updateEverywhere(userId, (user) {
      user.isLive = false;
      user.streams!.clear();
    });
  }

  /// Realtime: [userId] came online.
  void onUserConnected(String userId) {
    _updateEverywhere(userId, (user) => user.isOnline = true);
  }

  /// Realtime: [userId] went offline.
  void onUserDisConnected(String userId) {
    _updateEverywhere(userId, (user) => user.isOnline = false);
  }
}
