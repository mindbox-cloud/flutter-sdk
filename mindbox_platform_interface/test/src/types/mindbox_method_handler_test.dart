import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

// ignore_for_file: unchecked_use_of_nullable_value
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MindboxMethodHandler handler;

  setUp(() {
    handler = MindboxMethodHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, mindboxMockMethodCallHandler);
  });

  tearDown(
    () {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'getPlatformVersion',
    () async {
      expect(await handler.nativeSdkVersion, 'dummy-sdk-version');
    },
  );

  test(
    'init()',
    () async {
      final completer = Completer<String>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler
          .init(configuration: validConfig)
          .then((value) => completer.complete('initialized'));

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'init() forwards operationsDomain to native channel',
    () async {
      final capturedArgs = <String, dynamic>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'init') {
          capturedArgs.addAll(Map<String, dynamic>.from(call.arguments));
        }
        return mindboxMockMethodCallHandler(call);
      });

      await handler.init(
        configuration: Configuration(
          domain: 'domain',
          endpointIos: 'endpointIos',
          endpointAndroid: 'endpointAndroid',
          operationsDomain: 'operations.example.com',
        ),
      );

      expect(capturedArgs['operationsDomain'], 'operations.example.com');
    },
  );

  test(
    'init() forwards empty operationsDomain by default',
    () async {
      final capturedArgs = <String, dynamic>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'init') {
          capturedArgs.addAll(Map<String, dynamic>.from(call.arguments));
        }
        return mindboxMockMethodCallHandler(call);
      });

      await handler.init(
        configuration: Configuration(
          domain: 'domain',
          endpointIos: 'endpointIos',
          endpointAndroid: 'endpointAndroid',
        ),
      );

      expect(capturedArgs.containsKey('operationsDomain'), isTrue);
      expect(capturedArgs['operationsDomain'], '');
    },
  );

  test(
    'When config is invalid, init() calling should throws MindboxException',
    () async {
      final invalidConfig = Configuration(
        domain: '',
        endpointIos: '',
        endpointAndroid: '',
        subscribeCustomerIfCreated: true,
      );

      expect(() async => handler.init(configuration: invalidConfig),
          throwsA(isA<MindboxInitializeError>()));
    },
  );

  test(
    'When SDK was initialized, getDeviceUUID() should return device uuid',
    () async {
      final completer = Completer<String>();

      handler.getDeviceUUID(callback: (uuid) => completer.complete(uuid));

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      expect(await completer.future, equals('dummy-device-uuid'));
    },
  );

  test(
    'When SDK was not initialized, getDeviceUUID() should not return '
    'device uuid',
    () async {
      final completer = Completer<String>();

      handler.getDeviceUUID(callback: (uuid) => completer.complete(uuid));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'When SDK was initialized, getToken() should return token',
    () async {
      final completer = Completer<String>();

      handler.getToken(
          callback: (deviceToken) => completer.complete(deviceToken));

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      expect(await completer.future, equals('dummy-token'));
    },
  );

  test(
    'When SDK was not initialized, getToken() should not return token',
    () async {
      final completer = Completer<String>();

      handler.getToken(
          callback: (deviceToken) => completer.complete(deviceToken));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'onPushClickReceived()',
    () async {
      final StubMindboxMethodHandler handler = StubMindboxMethodHandler();
      final completer = Completer<String>();

      handler.handlePushClick(callback: (url) => completer.complete(url));

      expect(await completer.future, equals('dummy-url'));
    },
  );

  test(
    'When SDK was initialized, executeAsyncOperation() should be invoked',
    () async {
      final completer = Completer<String>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      handler.executeAsyncOperation(
        operationSystemName: 'dummy-name',
        operationBody: {'dummy-key': 'dummy-value'},
      ).whenComplete(() => completer.complete('invoked'));

      await handler.init(configuration: validConfig);

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'When SDK not initialized, executeAsyncOperation() should not be invoked',
    () async {
      final completer = Completer<String>();

      handler.executeAsyncOperation(
        operationSystemName: 'dummy-name',
        operationBody: {'dummy-key': 'dummy-value'},
      ).whenComplete(() => completer.complete('invoked'));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'When SDK was initialized, executeSyncOperation() should be invoked',
    () async {
      final completer = Completer<String>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      handler
          .executeSyncOperation(
            operationSystemName: 'dummy-name',
            operationBody: {'dummy-key': 'dummy-value'},
            onSuccess: (success) {},
            onError: (error) {},
          )
          .whenComplete(() => completer.complete('invoked'));

      await handler.init(configuration: validConfig);

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'When SDK not initialized, executeSyncOperation() should not be invoked',
    () async {
      final completer = Completer<String>();

      handler
          .executeSyncOperation(
            operationSystemName: 'dummy-name',
            operationBody: {'dummy-key': 'dummy-value'},
            onSuccess: (success) {},
            onError: (error) {},
          )
          .whenComplete(() => completer.complete('invoked'));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'When no errors occur during execution, executeSyncOperation() should '
    'return success response',
    () async {
      final completer = Completer<String>();

      handler.executeSyncOperation(
        operationSystemName: 'dummy-valid-name',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (response) => completer.complete(response),
        onError: (error) => completer.complete(error.toString()),
      );

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      expect(await completer.future, equals('dummy-response'));
    },
  );

  test(
    'When validation data is incorrect, executeSyncOperation() should throw'
    'MindboxValidationError to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-validation-error',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxValidationError>()));
    },
  );

  test(
    'When operation data is incorrect, executeSyncOperation() should throw'
    'MindboxProtocolError to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-invalid-system-name',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxProtocolError>()));
    },
  );

  test(
    'When server returns internal error, executeSyncOperation() should throw'
    'MindboxServerError to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-server-error',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxServerError>()));
    },
  );

  test(
    'When network error occurred, executeSyncOperation() should '
    'return MindboxNetworkError to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-network-error',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxNetworkError>()));
    },
  );

  test(
    'When Mindbox SDK internal error occurred, executeSyncOperation() should '
    'return MindboxInternalError to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-internal-error',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxInternalError>()));
    },
  );

  test(
    'When response data from native Mindbox SDK is empty or null , '
    'executeSyncOperation() should return MindboxInternalError '
    'to onError callback',
    () async {
      final completer = Completer<Exception>();

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await handler.init(configuration: validConfig);

      handler.executeSyncOperation(
        operationSystemName: 'dummy-null-error-message',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxInternalError>()));
    },
  );

  test(
    'Verify that init completes even if pending getDeviceUUID hangs, allowing retries',
    () async {
      int getDeviceUUIDCallCount = 0;

      // Mock handler that hangs on first getDeviceUUID
      Future slowMockMethodCallHandler(MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'init':
            return Future.value(true);
          case 'getDeviceUUID':
            getDeviceUUIDCallCount++;
            if (getDeviceUUIDCallCount == 1) {
              // First call hangs (pending one)
              return Completer<String>().future;
            } else {
              // Subsequent calls succeed
              return Future.value('retry-uuid');
            }
          case 'writeNativeLog':
            return Future.value(null);
          default:
            return 'dummy-response';
        }
      }

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, slowMockMethodCallHandler);

      // 1. Call getDeviceUUID before init. It goes to pending.
      bool callback1Called = false;
      handler.getDeviceUUID(callback: (uuid) {
        callback1Called = true;
      });

      // 2. Call init.
      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      // This should now complete even though the first getDeviceUUID is hanging
      // Adding timeout to fail faster if regression occurs (hangs indefinitely)
      await handler
          .init(configuration: validConfig)
          .timeout(const Duration(seconds: 5));

      expect(getDeviceUUIDCallCount, equals(1),
          reason: 'First call should have been triggered');
      expect(callback1Called, isFalse,
          reason: 'First callback is still hanging');

      // 3. Call getDeviceUUID again (retry).
      // This should succeed because init is complete.
      final completer = Completer<String>();
      handler.getDeviceUUID(callback: (uuid) => completer.complete(uuid));

      final result = await completer.future.timeout(const Duration(seconds: 1));

      expect(result, equals('retry-uuid'));
      expect(getDeviceUUIDCallCount, equals(2));
    },
  );
}

class StubMindboxMethodHandler {
  void handlePushClick({required Function(String url) callback}) {
    callback('dummy-url');
  }
}
