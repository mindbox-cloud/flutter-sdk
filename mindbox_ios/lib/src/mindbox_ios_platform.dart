import 'package:flutter/services.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

/// An [MindboxPlatform] that wraps Mindbox iOs SDK.
class MindboxIosPlatform extends MindboxPlatform {
  MindboxIosPlatform._();

  static const MethodChannel _channel =
      MethodChannel('mindbox.cloud/flutter-sdk');

  /// Registers this class as the default instance of [InAppPurchasePlatform].
  static void registerPlatform() {
    /// Register the platform instance with the plugin platform interface.
    MindboxPlatform.instance = MindboxIosPlatform._();
  }

  /// Returns SDK version or empty string("") on error
  @override
  Future<String> get sdkVersion async =>
      await _channel.invokeMethod('getSdkVersion');

  /// Initializes the SDK for further work
  @override
  Future<void> init({required Configuration configuration}) async {
    await _channel.invokeMethod(
      'init',
      {
        'domain': configuration.domain,
        'endpoint': configuration.endpoint,
      },
    );
  }
}
