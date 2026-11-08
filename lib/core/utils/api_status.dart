abstract class ApiStatus {}

class Success extends ApiStatus {
  int code;
  dynamic data;
  Success({required this.code, required this.data});
}

class Failure extends ApiStatus {
  int code;
  dynamic errorResponse;
  Failure({required this.code, required this.errorResponse});
}
