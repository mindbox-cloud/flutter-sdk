import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

/// An [MindboxPlatform] that wraps Mindbox iOS SDK.
class MindboxIosPlatform extends MindboxPlatform {
  MindboxIosPlatform._();

  final MindboxMethodHandler _methodHandler = MindboxMethodHandler();

  /// Registers this class as the default instance of [MindboxPlatform].
  static void registerPlatform() {
    /// Register the platform instance with the plugin platform interface.
    MindboxPlatform.instance = MindboxIosPlatform._();
  }

  /// Returns native SDK version or "Unknown" on error.
  @override
  Future<String> get nativeSdkVersion async => _methodHandler.nativeSdkVersion;

  /// Initializes the SDK for further work.
  ///
  /// You can call this method multiple times to set new configuration params.
  /// Read more about [Configuration] parameter.
  @override
  Future<void> init({required Configuration configuration}) async {
    await _methodHandler.init(configuration: configuration);
  }

  /// Returns device UUID string to callback.
  @override
  void getDeviceUUID({required Function(String uuid) callback}) {
    _methodHandler.getDeviceUUID(callback: callback);
  }

  /// Returns token to callback.
  @override
  void getToken({required Function(String token) callback}) {
    _methodHandler.getToken(callback: callback);
  }

  /// Returns token to callback.
  @override
  void getTokens({required Function(String token) callback}) {
    _methodHandler.getTokens(callback: callback);
  }

  /// Method for managing sdk logging
  @override
  void setLogLevel({required LogLevel logLevel}) {
    _methodHandler.setLogLevel(logLevel: logLevel);
  }

  /// Returns link from push to callback.
  @override
  void onPushClickReceived({
    required PushClickHandler handler,
  }) {
    _methodHandler.handlePushClick(handler: handler);
  }

  /// Returns id, redirectUrl and payload from In-app to callback.
  @override
  void onInAppClickRecieved({required InAppClickHandler handler}) {
    _methodHandler.handleInAppClick(handler: handler);
  }

  /// Returns id from In-app to callback.
  @override
  void onInAppismissed({required InAppDismissedHandler handler}) {
    _methodHandler.handleInAppDismiss(handler: handler);
  }

  /// Method for register a custom event.
  @override
  Future<void> executeAsyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
  }) async {
    _methodHandler.executeAsyncOperation(
      operationSystemName: operationSystemName,
      operationBody: operationBody,
    );
  }

  /// Method for executing an operation synchronously.
  @override
  Future<void> executeSyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
    required Function(String response) onSuccess,
    required Function(MindboxError error) onError,
  }) async {
    _methodHandler.executeSyncOperation(
      operationSystemName: operationSystemName,
      operationBody: operationBody,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  @override
  void registerInAppCallbacks({required List<InAppCallback> inAppCallbacks}) {
    _methodHandler.registerInAppCallbacks(callbacks: inAppCallbacks);
  }

  // Method for to send notification permission status
  @override
  void updateNotificationPermissionStatus({required bool granted}) {
    _methodHandler.updateNotificationPermissionStatus(granted: granted);
  }

  /// Writes a log message to the native Mindbox logging system.
  @override
  void writeNativeLog({required String message, required LogLevel logLevel}) {
    _methodHandler.writeNativeLog(message: message, logLevel: logLevel);
  }
}
