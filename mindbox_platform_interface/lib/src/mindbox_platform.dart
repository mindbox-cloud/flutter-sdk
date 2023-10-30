import '../mindbox_platform_interface.dart';

/// The interface that implementations of 'mindbox' must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `mindbox` does not consider newly added methods to be breaking changes.
/// Extending this class(using `extends`) ensures that the subclass will get the
/// default implementation, while platform implementations that `implements`
/// this interface will be broken by newly added [MindboxPlatform] methods.
abstract class MindboxPlatform {
  /// Should only be accessed after setter is called.
  static late MindboxPlatform _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [MindboxPlatform] when they register themselves.
  // ignore: unnecessary_getters_setters
  static set instance(MindboxPlatform instance) {
    _instance = instance;
  }

  /// The instance of [MindboxPlatform] to use.
  ///
  /// Must be set before accessing.
  // ignore: unnecessary_getters_setters
  static MindboxPlatform get instance => _instance;

  /// Initializes the SDK for further work
  ///
  /// You can call this method multiple times to set new configuration params.
  /// Read more about [Configuration] parameter.
  Future<void> init({required Configuration configuration}) =>
      throw UnimplementedError('init() has not been implemented.');

  /// Returns native SDK version.
  Future<String> get nativeSdkVersion =>
      throw UnimplementedError('sdkVersion has not been implemented.');

  /// Method to obtain device UUID.
  void getDeviceUUID({required Function(String) callback}) =>
      throw UnimplementedError('getDeviceUUID() has not been implemented.');

  /// Method to obtain token.
  void getToken({required Function(String) callback}) =>
      throw UnimplementedError('getToken() has not been implemented.');

  /// Method for handling push-notification click. Returns link and payload to
  /// callback.
  void onPushClickReceived({
    required PushClickHandler handler,
  }) =>
      throw UnimplementedError(
          'onPushClickReceived() has not been implemented.');

  /// Method for handling In-app click. Returns id, payload and url to
  /// callback.
  ///
  /// Deprecated - Use [registerInAppCallbacks] method instead
  @Deprecated('Use method registerInAppCallbacks')
  void onInAppClickRecieved({
    required InAppClickHandler handler,
  }) =>
      throw UnimplementedError(
          'onInAppClickRecieved() has not been implemented.');

  /// Method for handling In-app dismiss. Returns id to
  /// callback.
  ///
  /// Deprecated - Use [registerInAppCallbacks] method instead
  @Deprecated('Use method registerInAppCallbacks')
  void onInAppismissed({
    required InAppDismissedHandler handler,
  }) =>
      throw UnimplementedError(
          'onInAppismissed() has not been implemented.');

  /// Method for register a custom event.
  Future<void> executeAsyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
  }) =>
      throw UnimplementedError(
          'executeAsyncOperation() has not been implemented.');

  /// Method for executing an operation synchronously.
  Future<void> executeSyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
    required Function(String response) onSuccess,
    required Function(MindboxError error) onError,
  }) =>
      throw UnimplementedError(
          'executeSyncOperation() has not been implemented.');

  /// Registers a list of InAppCallback instances to handle clicks and dismiss.
  ///
  /// This method allows you to register one or more of the following callbacks:
  /// - [UrlInAppCallback] for handling in-app messages
  /// by opening an associated URL.
  /// - [EmptyInAppCallback] for handling in-app messages without performing
  /// any actions.
  /// - [CopyPayloadInAppCallback] for handling in-app messages by copying
  /// the associated payload to the clipboard.
  /// - [CustomInAppCallback] for providing custom click and dismiss handlers
  /// for in-app messages.
  ///
  /// [inAppCallbacks] is a required list of InAppCallback instances
  /// to be registered for handling in-app message events.
  ///
  /// If this method is not called, a default behavior will be implemented.
  /// The default behavior will open the link from
  /// the 'redirectUrl' parameter and copy the payload to the clipboard
  /// if it is not in JSON or XML format.
  void registerInAppCallbacks({required List<InAppCallback> inAppCallbacks}) =>
      throw UnimplementedError(
          'registerInAppCallbacks() has not been implemented.');

  /// Method for managing SDK logging
  void setLogLevel({required LogLevel logLevel}) =>
      throw UnimplementedError(
          'setLogLevel() has not been implemented.');
}



