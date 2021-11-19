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
        if (ServicesBinding.instance == null) {
          throw MindboxInitializeError(
              message: 'Initialization error',
              data:
                  'Try to invoke \'WidgetsFlutterBinding.ensureInitialized()\' '
                  'before initialization.');
        }
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
              final mindboxError = _convertPlatformExceptionToMindboxError(e);
              operation.errorCallback!(mindboxError);
            }
          });
        }
        _pendingCallbackMethods.clear();
        _pendingOperations.clear();
        _initialized = true;
      }
    } on PlatformException catch (e) {
      throw MindboxInitializeError(
          message: e.message ?? '', data: e.details ?? '');
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
    required Function(String success) onSuccess,
    required Function(MindboxError) onError,
  }) async {
    if (_initialized) {
      channel.invokeMethod('executeSyncOperation', [
        operationSystemName,
        jsonEncode(operationBody),
      ]).then((result) {
        onSuccess(result);
      }, onError: (e) {
        final mindboxError = _convertPlatformExceptionToMindboxError(e);
        onError(mindboxError);
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

  MindboxError _convertPlatformExceptionToMindboxError(dynamic e) {
    final PlatformException exception = e;
    Map response;
    if (exception.message == null || exception.message == '') {
      return MindboxInternalError(
          message: 'Empty or null error message', data: '');
    }
    try {
      response = jsonDecode(exception.message!);
    } on FormatException catch (e) {
      return MindboxInternalError(message: e.message, data: '');
    } on Exception {
      return MindboxInternalError(message: 'Data parsing error', data: '');
    }
    if (response.containsKey('type') && response.containsKey('data')) {
      final type = response['type'];
      final Map data = response['data'];
      switch (type) {
        case 'MindboxError':
          switch (data['status']) {
            case 'ValidationError':
              return MindboxValidationError(
                message: data['validationMessages'].toString(),
                data: data.toString(),
                code: '200',
              );
            case 'ProtocolError':
              return MindboxProtocolError(
                message: data['errorMessage'].toString(),
                data: data.toString(),
                code: data['httpStatusCode'].toString(),
              );
            case 'InternalServerError':
              return MindboxServerError(
                message: data['errorMessage'].toString(),
                data: data.toString(),
                code: data['httpStatusCode'].toString(),
              );
            default:
              return MindboxInternalError(
                message: 'Unknown error status',
                data: data.toString(),
              );
          }
        case 'NetworkError':
          return MindboxNetworkError(
              message: data['errorMessage'].toString(), data: data.toString());
        case 'InternalError':
          return MindboxInternalError(
              message: data['errorMessage'].toString(), data: data.toString());
        default:
          return MindboxInternalError(
            message: 'Empty or unknown error type',
            data: data.toString(),
          );
      }
    } else {
      return MindboxInternalError(
          message: 'Response does not contain the required keys',
          data: exception.message!);
    }
  }
}
