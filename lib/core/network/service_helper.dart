import 'package:flutter/foundation.dart';

import '../session/session_manager.dart';
import '../helpers/store_helper.dart';
import '../utils/api_status.dart';
import 'interceptor.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ServiceHelper {
  final http.Client client;
  final StoreHelper storeHelper;
  late final InterceptorClient _client;

  ServiceHelper({required this.client, required this.storeHelper}) {
    _client = InterceptorClient(client);
  }

  Map<String, String> headers() => {
    "Content-Type": "application/json",
    'Accept': 'application/json',
  };

  // authorized headers
  Map<String, String> authedHeaders(String token) => {
    "Content-Type": "application/json",
    'Accept': 'application/json',
    'Authorization': "Bearer $token",
  };

  Future<ApiStatus> getHelper({required String target, String? token}) async {
    final url = target.startsWith('http')
        ? Uri.parse(target)
        : Uri.parse("${Constants.baseUrl}$target");
    try {
      final response = await _client.get(url, headers: getHeaders(token));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiStatus> putHelper({
    required String target,
    String? token,
    dynamic body,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$target");
    final encoding = Encoding.getByName('utf-8');
    try {
      final response = await _client.put(
        url,
        headers: getHeaders(token),
        body: jsonEncode(body),
        encoding: encoding,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiStatus> putMultipartHelper({
    required String target,
    String? token,
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$target");
    final request = http.MultipartRequest('PUT', url)
      ..headers.addAll(getHeaders(token))
      ..files.addAll(files);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<http.MultipartFile> createMultipartFile(
    String field,
    File file,
  ) async {
    return await http.MultipartFile.fromPath(field, file.path);
  }

  Map<String, String> getHeaders(String? token) {
    return token == null
        ? headers()
        : authedHeaders(storeHelper.getAccessToken());
  }

  Future<ApiStatus> postHelper({
    required String target,
    String? token,
    dynamic data,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$target");
    final encoding = Encoding.getByName('utf-8');
    try {
      final response = await _client.post(
        url,
        headers: getHeaders(token),
        body: jsonEncode(data),
        encoding: encoding,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiStatus> multiPartRequestService({
    required File file,
    required Map<String, dynamic> data,
    required String endPoint,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}$endPoint');
    final token = storeHelper.getAccessToken();
    final request = http.MultipartRequest('POST', url)
      ..headers["Authorization"] = "Bearer $token"
      ..files.add(await http.MultipartFile.fromPath('image', file.path));

    // Add data entries as fields in the request
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiStatus _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return Success(data: response.body, code: 200);
      case 201:
        return Success(data: response.body, code: 200);
      case 401:
        // Signed-in session is no longer valid → end it cleanly (sockets,
        // in-memory user data, storage) and go to login. A 401 on a login
        // screen (no session yet) just returns the error.
        if (storeHelper.getAccessToken() != 'token') {
          SessionManager.endSession(notifyServer: false);
        }
        return Failure(
          code: Constants.unAuthorized,
          errorResponse: "un authorized request",
        );
      case 400:
        return Failure(
          code: Constants.badRequest,
          errorResponse: jsonDecode(response.body)['message'].toString(),
        );
      case 403:
        return Failure(
          code: Constants.methodNotAllowed,
          errorResponse: jsonDecode(response.body)['message'].toString(),
        );
      case 404:
        return Failure(
          code: Constants.invalidResponse,
          errorResponse: 'Page Not Found',
        );
      case 500:
        return Failure(
          code: Constants.invalidResponse,
          errorResponse: 'Server Error',
        );
      default:
        return Failure(
          code: Constants.unKnownError,
          errorResponse: 'Unexpected Error',
        );
    }
  }

  // Handle different exceptions
  ApiStatus _handleError(dynamic e) {
    if (e is HttpException || e is SocketException) {
      return Failure(
        code: Constants.noInternet,
        errorResponse: 'No Internet Connection',
      );
    } else if (e is FormatException) {
      return Failure(
        code: Constants.invalidFormat,
        errorResponse: 'Invalid Response Format',
      );
    } else {
      if (kDebugMode) {
        print("error : $e");
      }
      return Failure(
        code: Constants.unKnownError,
        errorResponse: '$e Unknown Error Occurred',
      );
    }
  }

  Future<ApiStatus> deleteHelper({
    required String target,
    String? token,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$target");
    final encoding = Encoding.getByName('utf-8');
    try {
      final response = await _client.delete(
        url,
        headers: getHeaders(token),
        body: data != null ? jsonEncode(data) : jsonEncode({'data': 'nothing'}),
        encoding: encoding,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiStatus> postMultipartHelper({
    required String target,
    String? token,
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    // Reports 0.0-1.0 as the request body is uploaded. Optional — only
    // wired up for large payloads (e.g. video) where showing real progress
    // matters; omit for small/instant uploads like images or audio notes.
    void Function(double progress)? onProgress,
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$target");
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(getHeaders(token))
      ..files.addAll(files);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = onProgress != null
          ? await _sendMultipartWithProgress(request, onProgress)
          : await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Streams a [MultipartRequest]'s already-encoded body through the
  /// underlying client while reporting how many bytes have gone out, so the
  /// UI can show a real upload percentage instead of a spinner. Doesn't
  /// duplicate the file in memory — bytes are forwarded as they're read.
  Future<http.StreamedResponse> _sendMultipartWithProgress(
    http.MultipartRequest request,
    void Function(double progress) onProgress,
  ) async {
    // finalize() computes the multipart boundary/content-type and content
    // length, mutating request.headers/contentLength as a side effect —
    // must be called before reading either.
    final byteStream = request.finalize();
    final total = request.contentLength;
    var sent = 0;

    final streamedRequest = http.StreamedRequest(request.method, request.url)
      ..headers.addAll(request.headers);
    if (total > 0) {
      streamedRequest.contentLength = total;
    }

    byteStream.listen(
      (chunk) {
        sent += chunk.length;
        if (total > 0) {
          onProgress((sent / total).clamp(0.0, 1.0));
        }
        streamedRequest.sink.add(chunk);
      },
      onDone: streamedRequest.sink.close,
      onError: (Object e, StackTrace st) {
        streamedRequest.sink.addError(e, st);
      },
      cancelOnError: true,
    );

    return _client.send(streamedRequest);
  }
}
