/// A normalised error thrown by the data layer (services/repositories) so the
/// UI never has to reason about transport-specific exceptions.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'AppException($message${statusCode != null ? ', status: $statusCode' : ''})';
}
