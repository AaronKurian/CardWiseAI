import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      fallbackBaseUrls = _fallbackBaseUrls
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty && url != (baseUrl ?? _defaultBaseUrl))
          .toList();

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const _fallbackBaseUrls = String.fromEnvironment(
    'API_FALLBACK_URLS',
    defaultValue: '',
  );

  final String baseUrl;
  final List<String> fallbackBaseUrls;
  String? token;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) => _send('PATCH', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path, expectsBody: false);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool expectsBody = true,
  }) async {
    if (baseUrl.isEmpty) {
      throw ApiException('API_BASE_URL is not configured', 0);
    }

    final urls = [baseUrl, ...fallbackBaseUrls];
    Object? lastNetworkError;

    for (final url in urls) {
      try {
        return await _sendOnce(
          method,
          Uri.parse('$url$path'),
          body: body,
          expectsBody: expectsBody,
        );
      } on ApiException {
        rethrow;
      } catch (error) {
        lastNetworkError = error;
      }
    }

    throw ApiException(lastNetworkError?.toString() ?? 'Connection failed', 0);
  }

  Future<Map<String, dynamic>> _sendOnce(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool expectsBody = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
      'PATCH' => await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported method $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decode(response.body);
      final message = decoded['error']?['message'] ?? 'Request failed';
      throw ApiException(message.toString(), response.statusCode);
    }

    if (!expectsBody || response.body.isEmpty) return {};
    return _decode(response.body);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
