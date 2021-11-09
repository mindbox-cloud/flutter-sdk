import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxAndroidPlatform.registerPlatform();
    channel.setMockMethodCallHandler(mindboxMockMethodCallHandler);
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test(
    'getPlatformVersion',
        () async {
      expect(await MindboxPlatform.instance.sdkVersion, 'dummy-sdk-version');
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
          throwsA(isA<MindboxException>()));
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
      final completer = Completer<String>();

      MindboxPlatform.instance
          .onPushClickReceived(callback: (url) => completer.complete(url));

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

      MindboxPlatform.instance.executeSyncOperation(
        operationSystemName: 'dummy-name',
        operationBody: {'dummy-key': 'dummy-value'},
      ).whenComplete(() => completer.complete('invoked'));

      await MindboxPlatform.instance.init(configuration: validConfig);

      expect(completer.isCompleted, isTrue);
    },
  );

  test(
    'When SDK not initialized, executeSyncOperation() should not be invoked',
        () async {
      final completer = Completer<String>();

      MindboxPlatform.instance.executeSyncOperation(
        operationSystemName: 'dummy-name',
        operationBody: {'dummy-key': 'dummy-value'},
      ).whenComplete(() => completer.complete('invoked'));

      expect(completer.isCompleted, isFalse);
    },
  );

  test(
    'When operationSystemName is valid, executeSyncOperation() should return'
        'success response',
        () async {
      final completer = Completer<String>();

      MindboxPlatform.instance.executeSyncOperation(
        operationSystemName: 'dummy-valid-name',
        operationBody: {'dummy-key': 'dummy-value'},
        onResponse: (response) => completer.complete(response),
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
    'When operationSystemName is invalid, executeSyncOperation() should return'
        'error',
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
          onError: (error) => completer.completeError(error));

      expect(() => completer.future, throwsA(isA<MindboxException>()));
    },
  );
}

class StubMindboxPlatform extends MindboxPlatform {
  StubMindboxPlatform._();

  static void registerPlatform() {
    MindboxPlatform.instance = StubMindboxPlatform._();
  }

  @override
  void onPushClickReceived({required Function(String url) callback}) {
    callback('dummy-url');
  }
}
