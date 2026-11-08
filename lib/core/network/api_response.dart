import 'dart:convert';

import '../constants.dart';
import '../error/exceptions.dart';
import '../utils/api_status.dart';

/// Helpers used by remote data sources to turn the raw [ApiStatus] returned
/// by `ServiceHelper` into decoded JSON or a [ServerException].
extension ApiStatusX on ApiStatus {
  /// Decoded JSON body of a successful response.
  ///
  /// Throws [ServerException] with the original code and message when the
  /// request failed, so repositories can map it to a `Failure`.
  dynamic get bodyOrThrow {
    final self = this;
    if (self is Success) return jsonDecode(self.data as String);
    throw toServerException();
  }

  /// Completes normally for a successful response, throws otherwise. Used
  /// for calls whose response body is not needed.
  void ensureSuccess() {
    if (this is! Success) throw toServerException();
  }

  ServerException toServerException() {
    final self = this;
    if (self is Failure) {
      return ServerException(
        code: self.code,
        message: self.errorResponse?.toString() ?? '',
      );
    }
    return ServerException(
      code: Constants.unKnownError,
      message: 'Unexpected Error',
    );
  }
}
