import 'dart:convert';

import 'package:flutter/services.dart';

import '../../mindbox_platform_interface.dart';

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

class _PendingPushData {
  _PendingPushData({required this.link, required this.payload});

  final String link;
  final String payload;
}

/// This class contains the necessary logic of the order of method calls
/// for the correct SDK working.
///
/// Platform implementations can use this class for platform calls.
class MindboxMethodHandler {
  bool _initialized = false;
  final List<_PendingCallbackMethod> _pendingCallbackMethods = [];
  final List<_PendingOperations> _pendingOperations = [];
  final List<_PendingPushData> _pendingPushData = [];
  final String _logPrefix = '[Flutter] ';
  PushClickHandler? _pushClickHandler;
  InAppClickHandler? _inAppClickHandler;
  InAppDismissedHandler? _inAppDismissedHandler;
  bool _methodHandlerSet = false;

  /// Returns native SDK version.
  Future<String> get nativeSdkVersion async =>
      await channel.invokeMethod('getSdkVersion');

  /// Initializes the SDK for further work.
  ///
  /// You can call this method multiple times to set new configuration params.
  /// Read more about [Configuration] parameter.
  Future<void> init({required Configuration configuration}) async {
    try {
      //ignore: unnecessary_null_comparison
      if (ServicesBinding.instance == null) {
        throw MindboxInitializeError(
            message: 'Initialization error',
            data: 'Try to invoke \'WidgetsFlutterBinding.ensureInitialized()\' '
                'before initialization.');
      }
      await channel.invokeMethod('init', configuration.toMap());

      if (!_methodHandlerSet) {
        _setMethodCallHandler();
      }

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
      _logInfo('Init in Flutter');
    } on PlatformException catch (e) {
      throw MindboxInitializeError(
          message: e.message ?? '', data: e.details ?? '');
    }
  }

  /// Returns device UUID to callback.
  void getDeviceUUID({required Function(String uuid) callback}) async {
    if (_initialized) {
      callback(await channel.invokeMethod('getDeviceUUID'));
    } else {
      _pendingCallbackMethods.add(_PendingCallbackMethod(
          methodName: 'getDeviceUUID', callback: callback));
    }
  }

  /// Returns token to callback.
  void getToken({required Function(String token) callback}) async {
    if (_initialized) {
      callback(await channel.invokeMethod('getToken') ?? 'null');
    } else {
      _pendingCallbackMethods.add(
          _PendingCallbackMethod(methodName: 'getToken', callback: callback));
    }
  }

  /// Method for managing SDK logging
  void setLogLevel({required LogLevel logLevel}) async {
    await channel.invokeMethod('setLogLevel', logLevel.index);
  }

  /// Method for sending notification permission status
  void updateNotificationPermissionStatus({required bool granted}) async {
    await channel.invokeMethod('updateNotificationPermissionStatus', granted);
  }

  /// Method for registers a list of InAppCallback instances to handle clicks
  /// and dismiss in in-apps.
  void registerInAppCallbacks({required List<InAppCallback> callbacks}) async {
   final List<String> types = [];
   bool custom = false;
   for (var element in callbacks) {
     if (element is CustomInAppCallback) {
       _inAppClickHandler = element.clickHandler;
       _inAppDismissedHandler = element.dismissedHandler;
       custom = true;
     }
     types.add(element.type);
   }

   if (custom == false
       && (_inAppClickHandler != null || _inAppDismissedHandler != null)) {
     types.add('CustomInAppCallback');
   }

   if (types.isNotEmpty) {
     await channel.invokeMethod('registerInAppCallbacks', types);
   }
  }

  /// Method for handling push-notification click.
  void handlePushClick({
    required PushClickHandler handler,
  }) {
    _pushClickHandler = handler;
    if (_pendingPushData.isNotEmpty){
      _logInfo('pendingPushData is not empty. Send data to methodHandler');
      for (final pushData in _pendingPushData){
        _logInfo('invoke pushClicked method from pending list');
        _sendPendingPushData(pushData);
      }
      _pendingPushData.clear();
    }
  }

  /// Method for handling In-app click.
  void handleInAppClick({
    required InAppClickHandler handler,
  }) {
    _inAppClickHandler = handler;
    registerInAppCallbacks(callbacks: [
      CustomInAppCallback(
          _inAppClickHandler ?? (id, redirectUrl, payload) => {},
          _inAppDismissedHandler ?? (id) => {}
      )
    ]);
  }

  /// Method for handling In-app dismiss.
  void handleInAppDismiss({
    required InAppDismissedHandler handler,
  }) {
    _inAppDismissedHandler = handler;
    registerInAppCallbacks(callbacks: [
      CustomInAppCallback(
          _inAppClickHandler ?? (id, redirectUrl, payload) => {},
          _inAppDismissedHandler ?? (id) => {}
      )
    ]);
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
  /// Writes a log message to the native Mindbox logging system.
  /// [message]: The message to be logged
  /// [logLevel]: The severity level of the log message [LogLevel]
  void writeNativeLog(
      {required String message, required LogLevel logLevel}) async {
    await channel
        .invokeMethod('writeNativeLog', [_logPrefix + message, logLevel.index]);
  }

  void _setMethodCallHandler() {
    channel.setMethodCallHandler((call) {
        switch (call.method) {
          case 'pushClicked':
            _logInfo('Handle method pushClicked');
            if (_pushClickHandler != null) {
              if (call.arguments is List) {
                _logInfo('Return data from push with parameters link = ${call.arguments[0]} and payload = ${call.arguments[1]}');
                _pushClickHandler?.call(call.arguments[0], call.arguments[1]);
              }
            } else {
              _logInfo('pushClickHandler not set. Save push data');
              _pendingPushData.add(_PendingPushData(link: call.arguments[0], payload: call.arguments[1]));
            }
            break;
          case 'onInAppClick':
            if (call.arguments is List) {
              _inAppClickHandler?.call(
                  call.arguments[0], call.arguments[1], call.arguments[2]);
            }
            break;
          case 'onInAppDismissed':
            if (call.arguments is String) {
              _inAppDismissedHandler?.call(call.arguments);
            }
            break;
        }
      return Future.value(true);
    });
    _methodHandlerSet = true;
  }

  void _logInfo(String message) {
    writeNativeLog(message: message, logLevel: LogLevel.info);
  }

  void _sendPendingPushData(_PendingPushData pushData) {
    try {
      _pushClickHandler?.call(pushData.link, pushData.payload);
    } catch (e) {
      _logInfo('error when send pending push data: $e');
    }
  }

}
