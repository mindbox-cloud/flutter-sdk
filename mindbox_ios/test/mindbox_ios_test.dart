import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

// ignore_for_file: unchecked_use_of_nullable_value
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxIosPlatform.registerPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, mindboxMockMethodCallHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'getPlatformVersion',
    () async {
      expect(
        await MindboxPlatform.instance.nativeSdkVersion,
        'dummy-sdk-version',
      );
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

      await MindboxPlatform.instance
          .init(configuration: validConfig)
          .then((value) => completer.complete('initialized'));

      expect(completer.isCompleted, isTrue);
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

      expect(
          () async =>
              MindboxPlatform.instance.init(configuration: invalidConfig),
          throwsA(isA<MindboxInitializeError>()));
    },
  );

  test(
    'When SDK was initialized, getDeviceUUID() should return device uuid',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance
          .getDeviceUUID(callback: (uuid) => completer.complete(uuid));

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await MindboxPlatform.instance.init(configuration: validConfig);

      expect(await completer.future, equals('dummy-device-uuid'));
    },
  );

  test(
    'When SDK was not initialized, getDeviceUUID() should not return '
    'device uuid',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance
          .getDeviceUUID(callback: (uuid) => completer.complete(uuid));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'When SDK was initialized, getToken() should return token',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance
          .getToken(callback: (deviceToken) => completer.complete(deviceToken));

      final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true,
      );

      await MindboxPlatform.instance.init(configuration: validConfig);

      expect(await completer.future, equals('dummy-token'));
    },
  );

  test(
    'When SDK was not initialized, getToken() should not return token',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance
          .getToken(callback: (deviceToken) => completer.complete(deviceToken));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'onPushClickReceived()',
    () async {
      StubMindboxPlatform.registerPlatform();
      final completer = Completer<List<String>>();

      MindboxPlatform.instance.onPushClickReceived(
          handler: (link, payload) => completer.complete([link, payload]));

      expect(await completer.future, equals(['dummy-url', 'dummy-payload']));
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

      MindboxPlatform.instance.executeAsyncOperation(
        operationSystemName: 'dummy-name',
        operationBody: {'dummy-key': 'dummy-value'},
      ).whenComplete(() => completer.complete('invoked'));

      await MindboxPlatform.instance.init(configuration: validConfig);

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'When SDK not initialized, executeAsyncOperation() should not be invoked',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance.executeAsyncOperation(
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

      MindboxPlatform.instance
          .executeSyncOperation(
            operationSystemName: 'dummy-name',
            operationBody: {'dummy-key': 'dummy-value'},
            onSuccess: (success) {},
            onError: (error) {},
          )
          .whenComplete(() => completer.complete('invoked'));

      await MindboxPlatform.instance.init(configuration: validConfig);

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'When SDK not initialized, executeSyncOperation() should not be invoked',
    () async {
      final completer = Completer<String>();

      MindboxPlatform.instance
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

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
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

      await MindboxPlatform.instance.init(configuration: validConfig);

      MindboxPlatform.instance.executeSyncOperation(
        operationSystemName: 'dummy-null-error-message',
        operationBody: {'dummy-key': 'dummy-value'},
        onSuccess: (success) {},
        onError: (error) => completer.completeError(error),
      );

      expect(() => completer.future, throwsA(isA<MindboxInternalError>()));
    },
  );

  test(
    'registerInAppCallbacks()',
    () async {
      StubMindboxPlatform.registerPlatform();
      final completerClick = Completer<List<String>>();
      final completerDismiss = Completer<List<String>>();

      MindboxPlatform.instance.registerInAppCallbacks(inAppCallbacks:[
        CustomInAppCallback(
            (id, redirectUrl, payload) =>
                    completerClick.complete([id, redirectUrl, payload]),
            (id) => completerDismiss.complete([id])
        )
      ]);

      expect(
          await completerClick.future,
          equals(['dummy-id', 'dummy-url', 'dummy-payload'])
      );
      expect(await completerDismiss.future, equals(['dummy-id']));
    },
  );
}

class StubMindboxPlatform extends MindboxPlatform {
  StubMindboxPlatform._();

  static void registerPlatform() {
    MindboxPlatform.instance = StubMindboxPlatform._();
  }

  @override
  void onPushClickReceived({
    required PushClickHandler handler,
  }) {
    handler('dummy-url', 'dummy-payload');
  }

  @override
  void registerInAppCallbacks({required List<InAppCallback> inAppCallbacks}) {
    for (var element in inAppCallbacks) {
      if (element is CustomInAppCallback) {
        element.clickHandler('dummy-id', 'dummy-url', 'dummy-payload');
        element.dismissedHandler('dummy-id');
      }
    }}
}
