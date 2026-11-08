import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';

class InterceptorClient extends http.BaseClient {
  final http.Client _inner;

  InterceptorClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _logRequest(request); // Log the request

    final response = await _inner.send(request);
    final modifiedResponse = await _cacheAndLogResponse(response);

    return modifiedResponse;
  }

  void _logRequest(http.BaseRequest request) {
    if (kDebugMode) {
      print('--- Request ---');
      print('URL: ${request.url}');
      print('Method: ${request.method}');
      print('Headers: ${request.headers}');
      if (request is http.Request) {
        print('Body: ${request.body}');
      }
      print('--------------');
    }
  }

  void printLongString(String text) {
    const chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      print(
        text.substring(
          i,
          i + chunkSize > text.length ? text.length : i + chunkSize,
        ),
      );
    }
  }

  void printPrettyJson(String responseBody) {
    try {
      final jsonObject = jsonDecode(responseBody);
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(jsonObject);

      const chunkSize = 800;
      for (int i = 0; i < prettyJson.length; i += chunkSize) {
        print(
          prettyJson.substring(
            i,
            i + chunkSize > prettyJson.length
                ? prettyJson.length
                : i + chunkSize,
          ),
        );
      }
    } catch (e) {
      // If it's not valid JSON, just print it in chunks.
      const chunkSize = 800;
      for (int i = 0; i < responseBody.length; i += chunkSize) {
        print(
          responseBody.substring(
            i,
            i + chunkSize > responseBody.length
                ? responseBody.length
                : i + chunkSize,
          ),
        );
      }
    }
  }

  Future<http.StreamedResponse> _cacheAndLogResponse(
    http.StreamedResponse response,
  ) async {
    final responseBytes = await response.stream
        .toBytes(); // Read and cache the stream

    if (kDebugMode) {
      final responseBody = utf8.decode(responseBytes);
      print('--- Response ---');
      print('Status Code: ${response.statusCode}');
      //print('Headers: ${response.headers}');
      print('------- body --------');

      printPrettyJson(responseBody);
      // debugPrint('Body: $responseBody');
      print('---------------');
    }

    // Create a new StreamedResponse with the cached bytes to allow further use
    return http.StreamedResponse(
      Stream.fromIterable([responseBytes]), // Recreate the stream
      response.statusCode,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
