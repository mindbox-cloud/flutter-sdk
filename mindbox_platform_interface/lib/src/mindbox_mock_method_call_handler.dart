import 'package:flutter/services.dart';
import '../mindbox_platform_interface.dart';

/// Mock platform channel method call handler
Future mindboxMockMethodCallHandler(MethodCall methodCall) async {
  switch (methodCall.method) {
    case 'init':
      final args = methodCall.arguments;
      final String domain = args['domain'];
      final String endpointIos = args['endpointIos'];
      final String endpointAndroid = args['endpointAndroid'];
      if (domain.isEmpty || endpointIos.isEmpty || endpointAndroid.isEmpty) {
        throw MindboxInitializeError(message: 'wrong configuration', data: '');
      }
      return Future.value(true);
    case 'getDeviceUUID':
      return Future.value('dummy-device-uuid');
    case 'getToken':
      return Future.value('dummy-token');
    case 'executeSyncOperation':
      final String operationSystemName = methodCall.arguments[0];
      if (operationSystemName == 'dummy-invalid-system-name') {
        throw MindboxProtocolError(
            message: 'Operation dummy-invalid-system-name not found',
            data:
                '{httpStatusCode: 400, status: ProtocolError, errorId: '
                    '819ef1a6-4a7e-44d6-b0ff-121fadbb4af2, errorMessage: '
                    'Operation dummy-invalid-system-name not found}',
            code: '400');
      }
      return Future.value('dummy-response');
    default:
      return 'dummy-sdk-version';
  }
}
