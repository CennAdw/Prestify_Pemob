import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  const ApiService({this.client});

  final http.Client? client;

  http.Client get _httpClient => client ?? http.Client();

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(endpoint, queryParameters);
    final response = await _httpClient
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decodeResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = _uri(endpoint);
    final response = await _httpClient
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 8));
    return _decodeResponse(response);
  }

  Uri _uri(String endpoint, [Map<String, String>? queryParameters]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return Uri.parse(
      '$normalizedBase/$normalizedEndpoint',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  dynamic _decodeResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Response API bukan JSON yang valid.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw ApiException(message ?? 'HTTP ${response.statusCode}');
    }

    if (decoded is Map<String, dynamic> && decoded['success'] == false) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Request API gagal.',
      );
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }

    return decoded;
  }
}