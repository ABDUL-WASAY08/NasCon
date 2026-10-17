import 'app_exception.dart';

/// Maps any thrown object to a short, user-safe message.
///
/// Raw exceptions and stack traces never reach the UI — this is the single
/// place that decides what a user is told.
abstract final class ErrorMapper {
  static const String offlineMessage =
      'You appear to be offline. Check your connection and try again.';
  static const String timeoutMessage =
      'The request took too long. Please try again.';
  static const String sessionExpiredMessage =
      'Your session has expired. Please sign in again.';
  static const String forbiddenMessage =
      'You do not have permission to do that.';
  static const String serverMessage =
      'Something went wrong on our side. Please try again.';
  static const String unexpectedMessage =
      'Something went wrong. Please try again.';

  static AppErrorKind kindOf(Object error) => error is AppException
      ? error.kind
      : AppErrorKind.unexpected;

  static bool isRetryable(Object error) => switch (kindOf(error)) {
    AppErrorKind.network ||
    AppErrorKind.timeout ||
    AppErrorKind.server => true,
    _ => false,
  };

  static bool isSessionExpired(Object error) =>
      kindOf(error) == AppErrorKind.unauthorized;

  static String messageFor(Object error) {
    if (error is! AppException) return unexpectedMessage;

    // A server-provided message is preferred when it is specific and safe.
    switch (error.kind) {
      case AppErrorKind.network:
        return offlineMessage;
      case AppErrorKind.timeout:
        return timeoutMessage;
      case AppErrorKind.unauthorized:
        return sessionExpiredMessage;
      case AppErrorKind.forbidden:
        return forbiddenMessage;
      case AppErrorKind.server:
        return error.message.isNotEmpty ? error.message : serverMessage;
      case AppErrorKind.notFound:
      case AppErrorKind.conflict:
      case AppErrorKind.validation:
        return error.message.isNotEmpty ? error.message : unexpectedMessage;
      case AppErrorKind.cancelled:
        return 'The request was cancelled.';
      case AppErrorKind.pendingContract:
        return error.message;
      case AppErrorKind.unexpected:
        return error.message.isNotEmpty ? error.message : unexpectedMessage;
    }
  }
}
