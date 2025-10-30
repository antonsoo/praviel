import 'dart:async';

import 'package:http/http.dart' as http;

import 'http_client_factory_io.dart'
    if (dart.library.html) 'http_client_factory_web.dart';

class CsrfClient extends http.BaseClient {
  CsrfClient({http.Client? inner})
    : _inner = inner ?? createBaseClient(),
      _ownsInner = inner == null;

  final http.Client _inner;
  final bool _ownsInner;
  String? _token;
  Future<void>? _prefetchFuture;

  static const _protectedMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  String? get token => _token;

  set token(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      _token = null;
      return;
    }
    if (_token == normalized) {
      return;
    }
    _token = normalized;
  }

  bool _shouldAttach(http.BaseRequest request) {
    return _protectedMethods.contains(request.method.toUpperCase());
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_shouldAttach(request) && _prefetchFuture != null) {
      try {
        await _prefetchFuture;
      } catch (_) {
        // Ignored: token bootstrap failures will surface on request response.
      }
    }
    if (_shouldAttach(request) &&
        _token != null &&
        request.headers['X-CSRF-Token'] == null) {
      request.headers['X-CSRF-Token'] = _token!;
    }

    final response = await _inner.send(request);

    final headerToken = response.headers['x-csrf-token'];
    if (headerToken != null && headerToken.isNotEmpty) {
      token = headerToken;
    } else {
      final cookieToken = _extractTokenFromSetCookie(
        response.headers['set-cookie'],
      );
      if (cookieToken != null && cookieToken.isNotEmpty) {
        token = cookieToken;
      }
    }

    return response;
  }

  String? _extractTokenFromSetCookie(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'csrf_token=([^;]+)').firstMatch(value);
    return match?.group(1);
  }

  Future<void> ensureToken(Uri uri) async {
    if (_token != null) {
      return;
    }
    if (_prefetchFuture != null) {
      return _prefetchFuture!;
    }
    _prefetchFuture = _fetchToken(uri);
    try {
      await _prefetchFuture;
    } finally {
      _prefetchFuture = null;
    }
  }

  Future<void> _fetchToken(Uri uri) async {
    final request = http.Request('GET', uri);
    final response = await send(request);
    await http.Response.fromStream(response);
  }

  @override
  void close() {
    if (_ownsInner) {
      _inner.close();
    }
  }
}
