import 'package:flutter/foundation.dart';

/// Structured error returned by the API (or synthesised by the client).
@immutable
class ApiError {
  const ApiError({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isConflict => statusCode == 409;

  bool get isValidation => statusCode == 422;

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) =>
      ApiError(
        message: json['message'] as String? ?? 'Unexpected error',
        code: json['code'] as String?,
        statusCode: statusCode,
        details: (json['details'] as Map?)?.cast<String, dynamic>(),
      );

  @override
  String toString() =>
      'ApiError($message${code != null ? ', code: $code' : ''}'
      '${statusCode != null ? ', status: $statusCode' : ''})';
}
