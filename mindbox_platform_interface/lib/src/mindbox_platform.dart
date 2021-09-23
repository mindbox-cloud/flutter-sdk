import 'types/configuration.dart';

/// The interface that implementations of mindbox must implement.
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
  static set instance(MindboxPlatform instance) {
    _instance = instance;
  }

  /// The instance of [MindboxPlatform] to use.
  ///
  /// Must be set before accessing.
  static MindboxPlatform get instance => _instance;

  /// Initializes the SDK for further work
  ///
  /// Read more about parameter [Configuration]
  Future<void> init({required Configuration configuration}) =>
      throw UnimplementedError('init() has not been implemented.');

  /// Returns SDK version.
  Future<String> get sdkVersion =>
      throw UnimplementedError('sdkVersion() has not been implemented.');
}
