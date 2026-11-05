import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON transport. Adds a bearer token when a session exists, decodes as
/// UTF-8 (Chinese text), and turns transport / HTTP failures into ApiException.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    String? Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  final String baseUrl;
  final http.Client _client;
  final String? Function()? _tokenProvider;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$base/$p');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final t = auth ? _tokenProvider?.call() : null;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<Json> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) =>
      _send(() => _client.get(_uri(path, query), headers: _headers(auth: auth)));

  Future<Json> post(String path, {Json? body, bool auth = false}) => _send(
        () => _client.post(
          _uri(path),
          headers: _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<Json> _send(Future<http.Response> Function() call) async {
    late final http.Response r;
    try {
      r = await call();
    } catch (e) {
      throw ApiException(-1, '网络请求失败: $e');
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(r.statusCode, 'HTTP ${r.statusCode}');
    }
    final Object? decoded = jsonDecode(utf8.decode(r.bodyBytes));
    if (decoded is Json) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw ApiException(r.statusCode, '响应不是 JSON 对象');
  }
}
