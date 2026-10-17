import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../../models/api_error.dart';

/// Supplies the current access token (and lets the app react to a 401).
typedef AccessTokenProvider = Future<String?> Function();

/// Central HTTP client.
///
/// Responsibilities: base URL + timeouts from [AppConfig], bearer-token
/// injection, error mapping to [AppException], and redacted logging. It never
/// retries non-idempotent requests and never logs credentials.
class ApiClient {
  ApiClient({
    required this.config,
    AccessTokenProvider? accessToken,
    void Function()? onUnauthorized,
    Dio? dio,
  }) : _accessToken = accessToken,
       _onUnauthorized = onUnauthorized,
       _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.connectTimeout,
      headers: const {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      // Let us handle non-2xx ourselves so the body drives the message.
      validateStatus: (status) => status != null && status < 500,
    );
    _dio.interceptors.add(_AuthInterceptor(this));
    if (kDebugMode) _dio.interceptors.add(_SafeLogInterceptor());
  }

  final AppConfig config;
  final Dio _dio;
  final AccessTokenProvider? _accessToken;
  final void Function()? _onUnauthorized;

  Dio get raw => _dio;

  Future<String?> _currentToken() async {
    try {
      return await _accessToken?.call();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await get(path, query: query);
    return _asObject(data);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await get(path, query: query);
    if (data is! List) {
      throw const AppException(
        'The server returned an unexpected response shape.',
        kind: AppErrorKind.server,
      );
    }
    return data
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    final data = await _send(
      () => _dio.post<dynamic>(
        path,
        data: body,
        options: _headers(idempotencyKey),
      ),
    );
    return _asObject(data);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    final data = await _send(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      ),
    );
    return _asObject(data);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    final data = await _send(
      () => _dio.put<dynamic>(
        path,
        data: body,
        options: _headers(idempotencyKey),
      ),
    );
    return _asObject(data);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    final data = await _send(
      () => _dio.delete<dynamic>(
        path,
        data: body,
        options: _headers(idempotencyKey),
      ),
    );
    return _asObject(data);
  }

  Options? _headers(String? idempotencyKey) {
    if (idempotencyKey == null) return null;
    return Options(headers: {'Idempotency-Key': idempotencyKey});
  }

  Map<String, dynamic> _asObject(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data == null) return const {};
    throw const AppException(
      'The server returned an unexpected response shape.',
      kind: AppErrorKind.server,
    );
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      final status = response.statusCode ?? 0;

      if (status >= 400) {
        final error = _errorFromResponse(response);
        if (status == 401) _onUnauthorized?.call();
        throw AppException.fromApiError(error);
      }
      return response.data;
    } on DioException catch (error) {
      throw _fromDioException(error);
    }
  }

  ApiError _errorFromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      return ApiError.fromJson(
        data.cast<String, dynamic>(),
        statusCode: response.statusCode,
      );
    }
    return ApiError(
      message: 'Request failed (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  AppException _fromDioException(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => AppException(
      'The connection timed out.',
      kind: AppErrorKind.timeout,
      cause: error,
    ),
    DioExceptionType.connectionError => AppException(
      'Unable to reach the server.',
      kind: AppErrorKind.network,
      cause: error,
    ),
    DioExceptionType.cancel => AppException(
      'Request cancelled.',
      kind: AppErrorKind.cancelled,
      cause: error,
    ),
    DioExceptionType.badCertificate => AppException(
      'The server certificate could not be verified.',
      kind: AppErrorKind.network,
      cause: error,
    ),
    _ => AppException(
      'An unexpected network error occurred.',
      kind: AppErrorKind.network,
      cause: error,
    ),
  };
}

/// Attaches the bearer token to every request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _client._currentToken();
    final path = options.path;
    final isPublicAuthRequest =
        path.endsWith('/auth/login') ||
        path.endsWith('/auth/register') ||
        path.endsWith('/auth/google');
    if (!isPublicAuthRequest && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Logs method, path and status only — never headers, bodies or tokens.
class _SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.baseUrl}${options.path}',
      name: 'api',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.path}',
      name: 'api',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log('✕ ${err.type.name} ${err.requestOptions.path}', name: 'api');
    handler.next(err);
  }
}
