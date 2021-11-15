import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';
import 'package:mindbox_platform_interface/src/channel.dart';
import 'package:mindbox_platform_interface/src/mindbox_mock_method_call_handler.dart';
import 'package:mindbox_platform_interface/src/types/mindbox_method_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MindboxMethodHandler handler;

  setUp(() {
    handler = MindboxMethodHandler();
    channel.setMockMethodCallHandler(mindboxMockMethodCallHandler);
  });

  tearDown(
        () {
      channel.setMockMethodCallHandler(null);
    },
  );

  test(
    'getPlatformVersion',
        () async {
      expect(await handler.sdkVersion, 'dummy-sdk-version');
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
    'When config is invalid, init() calling should throws MindboxException',
        () async {
      final invalidConfig = Configuration(
        domain: '',
        endpointIos: '',
        endpointAndroid: '',
        subscribeCustomerIfCreated: true,
      );

      expect(() async => handler.init(configuration: invalidConfig),
          throwsA(isA<MindboxException>()));
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
}

class StubMindboxMethodHandler {
  void handlePushClick({required Function(String url) callback}) {
    callback('dummy-url');
  }
}
