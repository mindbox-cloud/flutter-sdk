import 'package:flutter/services.dart';

import '../../mindbox_platform_interface.dart';
import '../channel.dart';

class _MethodCallback {
  _MethodCallback({required this.methodName, required this.callback});

  final String methodName;
  final Function callback;
}

/// This class contains the necessary logic of the order of method calls
/// for the correct SDK working.
///
/// Platform implementations can use this class for platform calls.
class MindboxMethodHandler {
  bool _initialized = false;
  final List<_MethodCallback> _callbacks = [];

  /// Returns SDK version
  Future<String> get sdkVersion async =>
      await channel.invokeMethod('getSdkVersion');

  /// Initializes the SDK for further work
  ///
  /// Read more about parameter [Configuration]
  Future<void> init({required Configuration configuration}) async {
    try {
      if (!_initialized) {
        await channel.invokeMethod('init', configuration.toMap());
        for (final methodCallback in _callbacks) {
          methodCallback
              .callback(await channel.invokeMethod(methodCallback.methodName));
        }
        _callbacks.clear();
        _initialized = true;
      }
    } on PlatformException catch (e) {
      throw MindboxException(
          message: e.message ?? '', details: e.details ?? '');
    }
  }

  /// Returns device UUID to callback
  void getDeviceUUID({required Function(String uuid) callback}) async {
    if (_initialized) {
      callback(await channel.invokeMethod('getDeviceUUID'));
    } else {
      _callbacks.add(
          _MethodCallback(methodName: 'getDeviceUUID', callback: callback));
    }
  }

  /// Returns token to callback
  void getToken({required Function(String token) callback}) async {
    if (_initialized) {
      callback(await channel.invokeMethod('getToken'));
    } else {
      _callbacks
          .add(_MethodCallback(methodName: 'getToken', callback: callback));
    }
  }
}
