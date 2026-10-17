import '../../models/api_error.dart';

/// How an error should be categorised for the UI.
enum AppErrorKind {
  /// Device appears to be offline or the host is unreachable.
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  cancelled,

  /// The feature exists in the UI but the backend contract has not been
  /// supplied yet. Never shown as a generic failure.
  pendingContract,
  unexpected,
}

/// A normalised error thrown by the data layer.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.kind = AppErrorKind.unexpected,
    this.statusCode,
    this.code,
    this.details,
    this.cause,
  });

  final String message;
  final AppErrorKind kind;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;
  final Object? cause;

  bool get isRetryable =>
      kind == AppErrorKind.network ||
      kind == AppErrorKind.timeout ||
      kind == AppErrorKind.server;

  factory AppException.fromApiError(ApiError error) => AppException(
    error.message,
    kind: _kindForStatus(error.statusCode),
    statusCode: error.statusCode,
    code: error.code,
    details: error.details,
  );

  /// Raised by API repositories whose endpoint has not been specified yet.
  factory AppException.pendingContract(String feature) => AppException(
    'The backend contract for "$feature" has not been supplied yet.',
    kind: AppErrorKind.pendingContract,
  );

  static AppErrorKind _kindForStatus(int? status) => switch (status) {
    401 => AppErrorKind.unauthorized,
    403 => AppErrorKind.forbidden,
    404 => AppErrorKind.notFound,
    409 => AppErrorKind.conflict,
    422 => AppErrorKind.validation,
    final s when s != null && s >= 500 => AppErrorKind.server,
    _ => AppErrorKind.unexpected,
  };

  @override
  String toString() =>
      'AppException($message, kind: ${kind.name}'
      '${statusCode != null ? ', status: $statusCode' : ''})';
}
