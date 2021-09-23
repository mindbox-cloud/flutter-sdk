import 'package:flutter/foundation.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

/// Basic Mindbox API
class Mindbox extends MindboxPlatform {
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

  @override
  Future<String> get sdkVersion async => MindboxPlatform.instance.sdkVersion;

  @override
  Future<void> init({required Configuration configuration}) async {
      MindboxPlatform.instance.init(configuration: configuration);
  }
}
