import '../mindbox_platform_interface.dart';

import 'types/configuration.dart';

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
  /// Read more about parameter [Configuration]
  Future<void> init({required Configuration configuration}) =>
      throw UnimplementedError('init() has not been implemented.');

  /// Returns SDK version.
  Future<String> get sdkVersion =>
      throw UnimplementedError('sdkVersion has not been implemented.');

  /// Method to obtain device UUID.
  void getDeviceUUID({required Function(String) callback}) =>
      throw UnimplementedError('getDeviceUUID() has not been implemented.');

  /// Method to obtain token.
  void getToken({required Function(String) callback}) =>
      throw UnimplementedError('getToken() has not been implemented.');

  /// Method for handling push-notification click. Returns link to callback.
  void onPushClickReceived({required Function(String) callback}) =>
      throw UnimplementedError(
          'onPushClickReceived() has not been implemented.');

  /// Method for register a custom event.
  Future<void> executeAsyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
  }) =>
      throw UnimplementedError(
          'onPushClickReceived() has not been implemented.');

  /// Method for executing an operation synchronously.
  Future<void> executeSyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
    required Function(String response) onSuccess,
    required Function(MindboxError error) onError,
  }) =>
      throw UnimplementedError(
          'executeSyncOperation() has not been implemented.');
}
