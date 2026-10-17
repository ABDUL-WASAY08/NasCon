import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Central HTTP client.
///
/// A singleton [Dio] configured with the app's base URL and timeouts, plus
/// helpers that translate [DioException]s into [AppException]s. Not wired to
/// any screen yet.
class ApiClient {
  ApiClient._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
          contentType: Headers.jsonContentType,
        ),
      );

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;

  Dio get raw => _dio;

  /// Attaches (or clears) the bearer token used on subsequent requests.
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) =>
      _request(() => _dio.post<T>(path, data: data));

  Future<T> put<T>(String path, {Object? data}) =>
      _request(() => _dio.put<T>(path, data: data));

  Future<T> delete<T>(String path, {Object? data}) =>
      _request(() => _dio.delete<T>(path, data: data));

  Future<T> _request<T>(Future<Response<T>> Function() send) async {
    try {
      final response = await send();
      final data = response.data;
      if (data == null) {
        throw const AppException('Empty response from server');
      }
      return data;
    } on DioException catch (error) {
      throw AppException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
        cause: error,
      );
    }
  }

  String _messageFor(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'The connection timed out. Please try again.',
    DioExceptionType.connectionError =>
      'Unable to reach the server. Check your connection.',
    DioExceptionType.badResponse => _badResponseMessage(error),
    DioExceptionType.cancel => 'Request cancelled.',
    DioExceptionType.badCertificate => 'Invalid server certificate.',
    _ => 'An unexpected error occurred.',
  };

  String _badResponseMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Something went wrong (${error.response?.statusCode}).';
  }
}
