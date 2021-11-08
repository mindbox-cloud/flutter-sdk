import 'dart:convert';

import 'package:flutter/services.dart';

import '../../mindbox_platform_interface.dart';
import '../channel.dart';

class _PendingCallbackMethod {
  _PendingCallbackMethod({
    required this.methodName,
    required this.callback,
  });

  final String methodName;
  final Function callback;
}

class _PendingOperations {
  _PendingOperations({
    required this.methodName,
    this.parameters,
    this.successCallback,
    this.errorCallback,
  });

  final String methodName;
  final dynamic parameters;
  final Function? successCallback;
  final Function? errorCallback;
}

/// This class contains the necessary logic of the order of method calls
/// for the correct SDK working.
///
/// Platform implementations can use this class for platform calls.
class MindboxMethodHandler {
  bool _initialized = false;
  final List<_PendingCallbackMethod> _pendingCallbackMethods = [];
  final List<_PendingOperations> _pendingOperations = [];

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
        for (final callbackMethod in _pendingCallbackMethods) {
          callbackMethod.callback(
              await channel.invokeMethod(callbackMethod.methodName) ?? 'null');
        }
        for (final operation in _pendingOperations) {
          channel.invokeMethod(operation.methodName, operation.parameters).then(
                  (result) {
                if (operation.successCallback != null) {
                  operation.successCallback!(result);
                }
              }, onError: (e) {
            if (operation.errorCallback != null) {
              final exception = MindboxException(
                  message: e.message ?? 'empty',
                  code: e.code,
                  details: e.details);
              operation.errorCallback!(exception);
            }
          });
        }
        _pendingCallbackMethods.clear();
        _pendingOperations.clear();
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
      _pendingCallbackMethods.add(_PendingCallbackMethod(
          methodName: 'getDeviceUUID', callback: callback));
    }
  }

  /// Returns token to callback
  void getToken({required Function(String token) callback}) async {
    if (_initialized) {
      callback(await channel.invokeMethod('getToken') ?? 'null');
    } else {
      _pendingCallbackMethods.add(
          _PendingCallbackMethod(methodName: 'getToken', callback: callback));
    }
  }

  /// Method for handling push-notification click
  void handlePushClick({required Function(String) callback}) {
    channel.setMethodCallHandler((call) {
      if (call.method == 'linkReceived') {
        callback(call.arguments);
      }
      return Future.value(true);
    });
  }

  /// Method for register a custom event.
  Future<void> executeAsyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
  }) async {
    if (_initialized) {
      channel.invokeMethod('executeAsyncOperation', [
        operationSystemName,
        jsonEncode(operationBody),
      ]);
    } else {
      _pendingOperations.add(_PendingOperations(
        methodName: 'executeAsyncOperation',
        parameters: [operationSystemName, jsonEncode(operationBody)],
      ));
    }
  }

  /// Method for executing an operation synchronously.
  Future<void> executeSyncOperation({
    required String operationSystemName,
    required Map<String, dynamic> operationBody,
    Function(String)? onSuccess,
    Function(MindboxException)? onError,
  }) async {
    if (_initialized) {
      channel.invokeMethod('executeSyncOperation', [
        operationSystemName,
        jsonEncode(operationBody),
      ]).then((result) {
        if (onSuccess != null) {
          onSuccess(result);
        }
      }, onError: (e) {
        if (onError != null) {
          final exception = MindboxException(
              message: e.message ?? 'empty', code: e.code, details: e.details);
          onError(exception);
        }
      });
    } else {
      _pendingOperations.add(_PendingOperations(
        methodName: 'executeSyncOperation',
        parameters: [operationSystemName, jsonEncode(operationBody)],
        successCallback: onSuccess,
        errorCallback: onError,
      ));
    }
  }
}
