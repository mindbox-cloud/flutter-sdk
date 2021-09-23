import 'package:flutter/foundation.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';
export 'package:mindbox_platform_interface/mindbox_platform_interface.dart'
    show MindboxException, Configuration;

/// Basic Mindbox API
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

  /// Returns SDK version
  ///
  /// On error returns "Unknown" on iOs platform and empty string("") on Android
  Future<String> get sdkVersion async => MindboxPlatform.instance.sdkVersion;

  /// Initializes the SDK for further work
  ///
  /// Read more about parameter [Configuration]
  Future<void> init({required Configuration configuration}) async {
    await MindboxPlatform.instance.init(configuration: configuration);
  }
}
