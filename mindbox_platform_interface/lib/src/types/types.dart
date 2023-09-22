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
  ///
  verbose,

  ///
  debug,

  ///
  info,

  ///
  warn,

  ///

  error,

  ///
  none
}

/// Defines a handler for In-app actions
abstract class InAppCallback {
  abstract String _type;

  /// Type of InAppCallback
  String get type => _type;
}

/// Handler for In-app actions.
/// It provides a default implementation for handling in-app messages
/// by opening an associated URL when an in-app message is tapped.
class UrlInAppCallback extends InAppCallback {
  @override
  String _type = 'UrlInAppCallback';
}

/// Handler for In-app actions that performs no actions.
/// The EmptyInAppCallback class provides a default implementation for handling
/// in-app messages without performing any actions upon tapping or dismissing
/// the in-app message
class EmptyInAppCallback extends InAppCallback {
  @override
  String _type = 'EmptyInAppCallback';
}

/// Handler for In-app actions that copies the payload to the clipboard.
/// The CopyPayloadInAppCallback class provides a default implementation
/// for handling in-app messages by copying the associated payload
/// to the clipboard when the in-app message is tapped.
class CopyPayloadInAppCallback extends InAppCallback {
  @override
  String _type = 'CopyPayloadInAppCallback';
}

/// Handler for In-app actions that allows custom implementation for handling
/// clicks and dismiss events. The CustomInAppCallback class provides
/// a flexible way to implement custom handling for in-app
/// clicks using the [InAppClickHandler] and dismiss events
/// using the [InAppDismissedHandler].
///
/// Example usage:
///
/// CustomInAppCallback(
///   clickHandler: (id, redirectUrl, payload) => { /* your custom click handling logic */ },
///   dismissedHandler: (id) => { /* your custom dismiss handling logic */ },
/// )
///
class CustomInAppCallback extends InAppCallback {

  /// Constructs a CustomInAppCallback with the provided click
  /// and dismiss handlers.
  CustomInAppCallback(this.clickHandler, this.dismissedHandler);

  /// [clickHandler] is the function to handle click events in the in-app
  final InAppClickHandler clickHandler;
  /// [dismissedHandler] is the function to handle dismiss events in the in-app
  final InAppDismissedHandler dismissedHandler;

  @override
  String _type = 'CustomInAppCallback';
}
