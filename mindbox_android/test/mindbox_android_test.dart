import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  const MethodChannel channel = MethodChannel('mindbox.cloud/flutter-sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxAndroidPlatform.registerPlatform();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'init':
          final args = methodCall.arguments;
          final String domain = args['domain'];
          final String endpointIos = args['endpointIos'];
          final String endpointAndroid = args['endpointAndroid'];
          if (domain.isEmpty ||
              endpointIos.isEmpty ||
              endpointAndroid.isEmpty) {
            throw MindboxException(message: 'wrong configuration');
          }
          return Future.value(true);
        case 'getDeviceUUID':
          return Future.value('dummy-device-uuid');
        case 'getToken':
          return Future.value('dummy-token');
        default:
          return '1.1.0';
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MindboxPlatform.instance.sdkVersion, '1.1.0');
  });

  test('init()', () async {
    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    await MindboxPlatform.instance.init(configuration: validConfig);
  });

  test('When config is invalid, init() calling should throws MindboxException',
      () async {
    final invalidConfig = Configuration(
        domain: '',
        endpointIos: '',
        endpointAndroid: '',
        subscribeCustomerIfCreated: true);

    expect(
        () async => MindboxPlatform.instance.init(configuration: invalidConfig),
        throwsA(isA<MindboxException>()));
  });

  test('When SDK was initialized, getDeviceUUID() should return device uuid',
      () async {
    final completer = Completer<String>();

    MindboxPlatform.instance
        .getDeviceUUID(callback: (uuid) => completer.complete(uuid));

    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    await MindboxPlatform.instance.init(configuration: validConfig);

    expect(completer.isCompleted, isTrue);
    expect(await completer.future, equals('dummy-device-uuid'));
  });

  test(
      'When SDK was not initialized, getDeviceUUID() should not return '
      'device uuid', () async {
    final completer = Completer<String>();

    MindboxPlatform.instance
        .getDeviceUUID(callback: (uuid) => completer.complete(uuid));

    expect(completer.isCompleted, isFalse);
  });

  test('When SDK was initialized, getToken() should return token', () async {
    final completer = Completer<String>();

    MindboxPlatform.instance
        .getToken(callback: (deviceToken) => completer.complete(deviceToken));

    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    await MindboxPlatform.instance.init(configuration: validConfig);

    expect(completer.isCompleted, isTrue);
    expect(await completer.future, equals('dummy-token'));
  });

  test('When SDK was not initialized, getToken() should not return token',
      () async {
    final completer = Completer<String>();

    MindboxPlatform.instance
        .getToken(callback: (deviceToken) => completer.complete(deviceToken));

    expect(completer.isCompleted, isFalse);
  });

  test('onPushClickReceived()', () async {
    StubMindboxPlatform.registerPlatform();
    final completer = Completer<String>();

    MindboxPlatform.instance
        .onPushClickReceived(callback: (url) => completer.complete(url));

    expect(completer.isCompleted, isTrue);
    expect(await completer.future, equals('dummy-url'));
  });
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
