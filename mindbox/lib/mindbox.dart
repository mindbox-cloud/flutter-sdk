import 'package:flutter/foundation.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';
export 'package:mindbox_platform_interface/mindbox_platform_interface.dart'
    show
        Configuration,
        MindboxError,
        MindboxProtocolError,
        MindboxNetworkError,
        MindboxInternalError,
        MindboxValidationError,
        MindboxServerError,
        LogLevel,
        InAppCallback,
        UrlInAppCallback,
        EmptyInAppCallback,
        CopyPayloadInAppCallback,
        CustomInAppCallback,
        InAppClickHandler,
        InAppDismissedHandler;

/// Basic Mindbox API.
class Mindbox {
  Mindbox._();

  static Mindbox? _instance;

  /// The instance of the [Mindbox] to use.
  static Mindbox get instance => _getOrCreateInstance();

  static Mindbox _getOrCreateInstance() {
    if (_instance != null) {
      return _instance!;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      MindboxAndroidPlatform.registerPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      MindboxIosPlatform.registerPlatform();
    }

    _instance = Mindbox._();
    return _instance!;
  }

  /// Returns SDK version.
  ///
  /// On error returns "Unknown" on iOS platform and empty string on Android.
  Future<String> get nativeSdkVersion async =>
      MindboxPlatform.instance.nativeSdkVersion;

  /// Initializes the SDK for further work.
  ///
  /// You can call this method multiple times to set new configuration params.
  /// Read more about [Configuration] parameter.
  void init({required Configuration configuration}) {
    MindboxPlatform.instance.init(configuration: configuration);
  }

  /// Method to obtain device UUID.
  ///
  /// Callback returns UUID when Mindbox SDK is initialized. See also [init].
  void getDeviceUUID(Function(String uuid) callback) {
    MindboxPlatform.instance.getDeviceUUID(callback: callback);
  }

  /// Method to obtain token.
  ///
  /// Callback returns token when Mindbox SDK is initialized. See also [init].
  void getToken(Function(String token) callback) {
    MindboxPlatform.instance.getToken(callback: callback);
  }

  /// Method for managing sdk logging
  void setLogLevel({required LogLevel logLevel}) {
    MindboxPlatform.instance.setLogLevel(logLevel: logLevel);
  }

  /// Method for handling push-notification click.
  ///
  /// Returns link from push-notification to callback.
  void onPushClickReceived(PushClickHandler handler) {
    MindboxPlatform.instance.onPushClickReceived(handler: handler);
  }

  /// Method for handling In-app click.
  ///
  /// Returns id, redirectUrl and payload from In-app to callback.
  ///
  /// Deprecated - Use [registerInAppCallbacks] method instead
  @Deprecated('Use method registerInAppCallbacks')
  void onInAppClickRecieved(InAppClickHandler handler) {
    // ignore: deprecated_member_use
    MindboxPlatform.instance.onInAppClickRecieved(handler: handler);
  }

  /// Method for handling In-app dismiss.
  ///
  /// Returns id when In-app dismiss to callback.
  ///
  /// Deprecated - Use [registerInAppCallbacks] method instead
  @Deprecated('Use method registerInAppCallbacks')
  void onInAppDismissed(InAppDismissedHandler handler) {
    // ignore: deprecated_member_use
    MindboxPlatform.instance.onInAppismissed(handler: handler);
  }

  /// Method for register a custom event.
  void executeAsyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
  }) async {
    MindboxPlatform.instance.executeAsyncOperation(
      operationSystemName: operationSystemName,
      operationBody: operationBody,
    );
  }

  /// Method for executing an operation synchronously.
  void executeSyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
    required Function(String response) onSuccess,
    required Function(MindboxError error) onError,
  }) async {
    MindboxPlatform.instance.executeSyncOperation(
      operationSystemName: operationSystemName,
      operationBody: operationBody,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Method for handling In-app click and dismiss. Returns id, payload and url
  /// to callback.
  void registerInAppCallback({required List<InAppCallback> callbacks}) {
    MindboxPlatform.instance.registerInAppCallbacks(inAppCallbacks: callbacks);
  }
}
