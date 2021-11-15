/// Mindbox error.
abstract class MindboxError implements Exception {
  /// Constructs a MindboxError.
  MindboxError({
    required this.message,
    required this.data,
  });

  /// Contains error message.
  final String message;

  /// Contains error data.
  final String data;

  @override
  String toString() {
    return '$message\n$data';
  }
}

/// Client error.
class MindboxValidationError extends MindboxError {
  /// Constructs a MindboxValidationError.
  MindboxValidationError({
    required String message,
    required String data,
    required this.code,
  }) : super(message: message, data: data);

  /// Contains error code.
  final String code;
}

/// Request error/server error.
class MindboxProtocolError extends MindboxError {
  /// Constructs a MindboxProtocolError.
  MindboxProtocolError({
    required String message,
    required String data,
    required this.code,
  }) : super(message: message, data: data);

  /// Contains error code.
  final String code;
}

/// Error for code 5xx.
class MindboxServerError extends MindboxError {
  /// Constructs a MindboxServerError.
  MindboxServerError({
    required String message,
    required String data,
    required this.code,
  }) : super(message: message, data: data);

  /// Contains error code.
  final String code;
}

/// Network error.
class MindboxNetworkError extends MindboxError {
  /// Constructs a MindboxNetworkError.
  MindboxNetworkError({
    required String message,
    required String data,
  }) : super(message: message, data: data);
}

/// Internal error.
class MindboxInternalError extends MindboxError {
  /// Constructs a MindboxInternalError.
  MindboxInternalError({
    required String message,
    required String data,
  }) : super(message: message, data: data);
}

