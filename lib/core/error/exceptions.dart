/// Raised by remote data sources when the API answers with anything other
/// than a success status. [code] mirrors the codes in `Constants`
/// (e.g. `Constants.badRequest`) and [message] is the text the server or the
/// HTTP layer produced, ready to be shown to the user when appropriate.
class ServerException implements Exception {
  final int code;
  final String message;

  const ServerException({required this.code, required this.message});

  @override
  String toString() => 'ServerException($code): $message';
}

/// Raised by local data sources when cached data is missing or unreadable.
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache miss']);

  @override
  String toString() => 'CacheException: $message';
}
