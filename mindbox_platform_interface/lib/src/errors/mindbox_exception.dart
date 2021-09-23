/// Mindbox exception
class MindboxException implements Exception{
  /// Constructs a MindboxException.
  MindboxException({required this.message, this.details = ''});

  /// Used to get exception message.
  final String message;

  /// Used to get exception details.
  final String details;

  @override
  String toString() => details.isEmpty ? message : '$message\n$details';
}