import 'package:flutter/services.dart';
import '../../mindbox_platform_interface.dart';

/// Mock platform channel method call handler.
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
      if (operationSystemName == 'dummy-validation-error') {
        throw PlatformException(
            message: '{"type":"MindboxError","data":{"status":"ValidationError"'
                ',"validationMessages": [{ "message":"e-mail is incorrect",'
                '"location":"/customer/email"},{"message":"add contact"}]}}',
            code: '200');
      }
      if (operationSystemName == 'dummy-invalid-system-name') {
        throw PlatformException(
            message: '{"type":"MindboxError","data":{"httpStatusCode":"400",'
                '"status":"ProtocolError",'
                '"errorId":"3a39477a-7f4e-49de-81e4-89e21f80140f",'
                '"errorMessage":"Operation dummy-invalid-system-name not '
                'found"}}',
            code: '400');
      }
      if (operationSystemName == 'dummy-server-error') {
        throw PlatformException(
            message: '{"type":"MindboxError","data":{"httpStatusCode":"500",'
                '"status":"InternalServerError",'
                '"errorId":"3a39477a-7f4e-49de-81e4-89e21f80140f",'
                '"errorMessage":"Server internal error"}}',
            code: '500');
      }
      if (operationSystemName == 'dummy-network-error') {
        throw PlatformException(
            message: '{"type":"NetworkError","data":{'
                '"errorMessage":"Network error"}}',
            code: '-1');
      }
      if (operationSystemName == 'dummy-internal-error') {
        throw PlatformException(
            message: '{"type":"InternalError","data":{'
                '"errorMessage":"Mindbox Internal error"}}',
            code: '-1');
      }
      if (operationSystemName == 'dummy-null-error-message') {
        throw PlatformException(
            message: null,
            code: '-1');
      }
      return Future.value('dummy-response');
    default:
      return 'dummy-sdk-version';
  }
}
