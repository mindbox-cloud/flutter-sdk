/// Mindbox exception
class MindboxException implements Exception {
  /// Constructs a MindboxException.
  MindboxException({
    required this.message,
    this.details,
    this.code = '-1',
  });

  /// Used to get exception message.
  final String message;

  /// Used to get exception details.
  final String? details;

  /// Used to get exception details.
  final String code;

  @override
  String toString() {
    if (details != null && code != '-1') {
      return '(code: $code) $message\n$details';
    }
    if(details != null && code == '-1'){
      return '$message\n$details';
    }
    if(details == null && code != '-1'){
      return '(code: $code) $message';
    }
    return message;
  }
}
