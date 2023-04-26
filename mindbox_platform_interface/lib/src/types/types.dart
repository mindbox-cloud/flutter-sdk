export 'configuration.dart';
export 'mindbox_method_handler.dart';
export 'mindbox_mock_method_call_handler.dart';

/// Defines a handler for notification data
typedef PushClickHandler = void Function(String link, String payload);

/// Defines a handler for In-app data
typedef InAppClickHandler = void Function(
    String id, String redirectUrl, String payload);

/// Defines a handler for In-app dismiss
typedef InAppDismissedHandler = void Function(String id);

/// SDK logging levels
enum LogLevel {
  verbose,
  debug,
  info,
  warn,
  error,
  none,
}
